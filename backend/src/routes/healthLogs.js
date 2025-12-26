const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const supabase = require('../services/supabase');
const { body, query, validationResult } = require('express-validator');

/**
 * GET /api/health-logs
 * Get all health logs for a specific dog
 * Query params: dogId (required), since (optional ISO date for incremental sync)
 */
router.get('/',
  authenticateToken,
  [
    query('dogId').notEmpty().withMessage('Dog ID is required'),
    query('since').optional().isISO8601().withMessage('Invalid date format')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { dogId, since } = req.query;

      // Verify dog belongs to user
      const { data: dog, error: dogError } = await supabase
        .from('dogs')
        .select('id')
        .eq('id', dogId)
        .eq('user_id', userId)
        .single();

      if (dogError || !dog) {
        return res.status(404).json({ error: 'Dog not found' });
      }

      // Build query
      let logsQuery = supabase
        .from('health_logs')
        .select('*')
        .eq('dog_id', dogId)
        .eq('user_id', userId)
        .order('timestamp', { ascending: false });

      // If 'since' is provided, only get logs updated after that time (for incremental sync)
      if (since) {
        logsQuery = logsQuery.gte('updated_at', since);
      }

      const { data: logs, error } = await logsQuery;

      if (error) {
        throw new Error('Failed to fetch health logs');
      }

      res.status(200).json({
        success: true,
        logs: logs || [],
        syncedAt: new Date().toISOString()
      });
    } catch (error) {
      console.error('Fetch health logs error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch health logs',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/health-logs
 * Create a new health log entry
 */
router.post('/',
  authenticateToken,
  [
    body('dogId').notEmpty().withMessage('Dog ID is required'),
    body('logType').notEmpty().withMessage('Log type is required'),
    body('timestamp').optional().isISO8601().withMessage('Invalid timestamp format'),
    body('clientId').optional().isString()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const {
        dogId,
        logType,
        timestamp,
        notes,
        mealType,
        amount,
        duration,
        activityType,
        moodLevel,
        symptomType,
        severityLevel,
        digestionQuality,
        supplementName,
        dosage,
        appointmentType,
        location,
        groomingType,
        treatName,
        waterAmount,
        clientId
      } = req.body;

      // Verify dog belongs to user
      const { data: dog, error: dogError } = await supabase
        .from('dogs')
        .select('id')
        .eq('id', dogId)
        .eq('user_id', userId)
        .single();

      if (dogError || !dog) {
        return res.status(404).json({ error: 'Dog not found' });
      }

      // Check for duplicate based on clientId (for idempotent sync)
      if (clientId) {
        const { data: existing } = await supabase
          .from('health_logs')
          .select('id')
          .eq('client_id', clientId)
          .single();

        if (existing) {
          // Return existing log instead of creating duplicate
          const { data: existingLog } = await supabase
            .from('health_logs')
            .select('*')
            .eq('id', existing.id)
            .single();

          return res.status(200).json({
            success: true,
            log: existingLog,
            duplicate: true
          });
        }
      }

      const newLog = {
        user_id: userId,
        dog_id: dogId,
        log_type: logType,
        timestamp: timestamp || new Date().toISOString(),
        notes: notes || null,
        meal_type: mealType || null,
        amount: amount || null,
        duration: duration || null,
        activity_type: activityType || null,
        mood_level: moodLevel !== undefined ? moodLevel : null,
        symptom_type: symptomType || null,
        severity_level: severityLevel !== undefined ? severityLevel : null,
        digestion_quality: digestionQuality || null,
        supplement_name: supplementName || null,
        dosage: dosage || null,
        appointment_type: appointmentType || null,
        location: location || null,
        grooming_type: groomingType || null,
        treat_name: treatName || null,
        water_amount: waterAmount || null,
        client_id: clientId || null
      };

      const { data: log, error } = await supabase
        .from('health_logs')
        .insert([newLog])
        .select()
        .single();

      if (error) {
        throw new Error('Failed to create health log');
      }

      res.status(201).json({
        success: true,
        log
      });
    } catch (error) {
      console.error('Create health log error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to create health log',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/health-logs/batch
 * Create multiple health log entries at once (for bulk sync)
 */
router.post('/batch',
  authenticateToken,
  [
    body('logs').isArray().withMessage('Logs must be an array'),
    body('logs.*.dogId').notEmpty().withMessage('Dog ID is required for each log'),
    body('logs.*.logType').notEmpty().withMessage('Log type is required for each log')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { logs } = req.body;

      if (logs.length === 0) {
        return res.status(200).json({
          success: true,
          created: [],
          duplicates: []
        });
      }

      // Get unique dogIds and verify they all belong to user
      const dogIds = [...new Set(logs.map(l => l.dogId))];
      const { data: dogs, error: dogsError } = await supabase
        .from('dogs')
        .select('id')
        .in('id', dogIds)
        .eq('user_id', userId);

      if (dogsError) {
        throw new Error('Failed to verify dog ownership');
      }

      const validDogIds = new Set(dogs.map(d => d.id));
      
      // Filter out logs for dogs that don't belong to user
      const validLogs = logs.filter(l => validDogIds.has(l.dogId));

      if (validLogs.length === 0) {
        return res.status(400).json({ error: 'No valid logs to create' });
      }

      // Check for existing clientIds
      const clientIds = validLogs.map(l => l.clientId).filter(Boolean);
      let existingClientIds = new Set();
      
      if (clientIds.length > 0) {
        const { data: existing } = await supabase
          .from('health_logs')
          .select('client_id')
          .in('client_id', clientIds);
        
        existingClientIds = new Set((existing || []).map(e => e.client_id));
      }

      // Separate new logs from duplicates
      const newLogs = [];
      const duplicateClientIds = [];

      for (const log of validLogs) {
        if (log.clientId && existingClientIds.has(log.clientId)) {
          duplicateClientIds.push(log.clientId);
        } else {
          newLogs.push({
            user_id: userId,
            dog_id: log.dogId,
            log_type: log.logType,
            timestamp: log.timestamp || new Date().toISOString(),
            notes: log.notes || null,
            meal_type: log.mealType || null,
            amount: log.amount || null,
            duration: log.duration || null,
            activity_type: log.activityType || null,
            mood_level: log.moodLevel !== undefined ? log.moodLevel : null,
            symptom_type: log.symptomType || null,
            severity_level: log.severityLevel !== undefined ? log.severityLevel : null,
            digestion_quality: log.digestionQuality || null,
            supplement_name: log.supplementName || null,
            dosage: log.dosage || null,
            appointment_type: log.appointmentType || null,
            location: log.location || null,
            grooming_type: log.groomingType || null,
            treat_name: log.treatName || null,
            water_amount: log.waterAmount || null,
            client_id: log.clientId || null
          });
        }
      }

      let createdLogs = [];
      if (newLogs.length > 0) {
        const { data, error } = await supabase
          .from('health_logs')
          .insert(newLogs)
          .select();

        if (error) {
          throw new Error('Failed to create health logs');
        }
        createdLogs = data || [];
      }

      res.status(201).json({
        success: true,
        created: createdLogs,
        duplicates: duplicateClientIds
      });
    } catch (error) {
      console.error('Batch create health logs error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to create health logs',
        message: error.message
      });
    }
  }
);

/**
 * PUT /api/health-logs/:id
 * Update a health log entry
 */
router.put('/:id',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const logId = req.params.id;
      const updates = req.body;

      // Verify log belongs to user
      const { data: existingLog, error: checkError } = await supabase
        .from('health_logs')
        .select('id')
        .eq('id', logId)
        .eq('user_id', userId)
        .single();

      if (checkError || !existingLog) {
        return res.status(404).json({ error: 'Health log not found' });
      }

      // Build update object (only allow certain fields to be updated)
      const allowedFields = [
        'log_type', 'timestamp', 'notes', 'meal_type', 'amount', 'duration',
        'activity_type', 'mood_level', 'symptom_type', 'severity_level',
        'digestion_quality', 'supplement_name', 'dosage', 'appointment_type',
        'location', 'grooming_type', 'treat_name', 'water_amount'
      ];

      const updateData = {};
      for (const field of allowedFields) {
        // Convert camelCase to snake_case for comparison
        const camelField = field.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
        if (updates[camelField] !== undefined) {
          updateData[field] = updates[camelField];
        } else if (updates[field] !== undefined) {
          updateData[field] = updates[field];
        }
      }

      if (Object.keys(updateData).length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }

      const { data: log, error } = await supabase
        .from('health_logs')
        .update(updateData)
        .eq('id', logId)
        .select()
        .single();

      if (error) {
        throw new Error('Failed to update health log');
      }

      res.status(200).json({
        success: true,
        log
      });
    } catch (error) {
      console.error('Update health log error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to update health log',
        message: error.message
      });
    }
  }
);

/**
 * DELETE /api/health-logs/:id
 * Soft delete a health log entry
 */
router.delete('/:id',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const logId = req.params.id;

      // Verify log belongs to user
      const { data: existingLog, error: checkError } = await supabase
        .from('health_logs')
        .select('id')
        .eq('id', logId)
        .eq('user_id', userId)
        .single();

      if (checkError || !existingLog) {
        return res.status(404).json({ error: 'Health log not found' });
      }

      // Soft delete
      const { error } = await supabase
        .from('health_logs')
        .update({ is_deleted: true })
        .eq('id', logId);

      if (error) {
        throw new Error('Failed to delete health log');
      }

      res.status(200).json({
        success: true,
        message: 'Health log deleted successfully'
      });
    } catch (error) {
      console.error('Delete health log error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to delete health log',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/health-logs/sync
 * Full sync endpoint - sends local changes, receives server changes
 * This is the main endpoint for bidirectional sync
 */
router.post('/sync',
  authenticateToken,
  [
    body('dogId').notEmpty().withMessage('Dog ID is required'),
    body('lastSyncAt').optional().isISO8601().withMessage('Invalid date format'),
    body('localLogs').optional().isArray()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { dogId, lastSyncAt, localLogs = [] } = req.body;

      // Verify dog belongs to user
      const { data: dog, error: dogError } = await supabase
        .from('dogs')
        .select('id')
        .eq('id', dogId)
        .eq('user_id', userId)
        .single();

      if (dogError || !dog) {
        return res.status(404).json({ error: 'Dog not found' });
      }

      const syncedAt = new Date().toISOString();
      let createdLogs = [];
      let duplicateClientIds = [];

      // Process local logs (upload to server)
      if (localLogs.length > 0) {
        const clientIds = localLogs.map(l => l.clientId).filter(Boolean);
        let existingClientIds = new Set();
        
        if (clientIds.length > 0) {
          const { data: existing } = await supabase
            .from('health_logs')
            .select('client_id')
            .in('client_id', clientIds);
          
          existingClientIds = new Set((existing || []).map(e => e.client_id));
        }

        const newLogs = [];
        for (const log of localLogs) {
          if (log.clientId && existingClientIds.has(log.clientId)) {
            duplicateClientIds.push(log.clientId);
          } else {
            newLogs.push({
              user_id: userId,
              dog_id: dogId,
              log_type: log.logType,
              timestamp: log.timestamp || new Date().toISOString(),
              notes: log.notes || null,
              meal_type: log.mealType || null,
              amount: log.amount || null,
              duration: log.duration || null,
              activity_type: log.activityType || null,
              mood_level: log.moodLevel !== undefined ? log.moodLevel : null,
              symptom_type: log.symptomType || null,
              severity_level: log.severityLevel !== undefined ? log.severityLevel : null,
              digestion_quality: log.digestionQuality || null,
              supplement_name: log.supplementName || null,
              dosage: log.dosage || null,
              appointment_type: log.appointmentType || null,
              location: log.location || null,
              grooming_type: log.groomingType || null,
              treat_name: log.treatName || null,
              water_amount: log.waterAmount || null,
              client_id: log.clientId || null
            });
          }
        }

        if (newLogs.length > 0) {
          const { data, error } = await supabase
            .from('health_logs')
            .insert(newLogs)
            .select();

          if (error) {
            console.error('Failed to insert logs:', error);
          } else {
            createdLogs = data || [];
          }
        }
      }

      // Get server logs updated since last sync
      let serverLogsQuery = supabase
        .from('health_logs')
        .select('*')
        .eq('dog_id', dogId)
        .eq('user_id', userId)
        .order('timestamp', { ascending: false });

      if (lastSyncAt) {
        serverLogsQuery = serverLogsQuery.gte('updated_at', lastSyncAt);
      }

      const { data: serverLogs, error: fetchError } = await serverLogsQuery;

      if (fetchError) {
        throw new Error('Failed to fetch server logs');
      }

      res.status(200).json({
        success: true,
        serverLogs: serverLogs || [],
        uploadedCount: createdLogs.length,
        duplicateClientIds,
        syncedAt
      });
    } catch (error) {
      console.error('Sync health logs error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to sync health logs',
        message: error.message
      });
    }
  }
);

module.exports = router;
