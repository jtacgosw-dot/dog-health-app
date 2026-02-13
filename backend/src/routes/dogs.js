const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const supabase = require('../services/supabase');
const { body, validationResult } = require('express-validator');

/**
 * GET /api/dogs
 * Get all dogs for current user
 */
router.get('/',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;

      const { data: dogs, error } = await supabase
        .from('dogs')
        .select('*')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', { ascending: false });

      if (error) {
        throw new Error('Failed to fetch dogs');
      }

      res.status(200).json({
        success: true,
        dogs: dogs || []
      });
    } catch (error) {
      console.error('Fetch dogs error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch dogs',
        message: error.message
      });
    }
  }
);

/**
 * GET /api/dogs/:id
 * Get a specific dog
 */
router.get('/:id',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const dogId = req.params.id;

      const { data: dog, error } = await supabase
        .from('dogs')
        .select('*')
        .eq('id', dogId)
        .eq('user_id', userId)
        .single();

      if (error || !dog) {
        return res.status(404).json({ error: 'Dog not found' });
      }

      res.status(200).json({
        success: true,
        dog
      });
    } catch (error) {
      console.error('Fetch dog error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch dog',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/dogs
 * Create a new dog profile
 */
router.post('/',
  authenticateToken,
  [
    body('name').notEmpty().withMessage('Dog name is required'),
    body('id').optional().isUUID().withMessage('ID must be a valid UUID'),
    body('breed').optional().isString(),
    body('ageYears').optional().isInt({ min: 0 }).withMessage('Age years must be a positive integer'),
    body('ageMonths').optional().isInt({ min: 0, max: 11 }).withMessage('Age months must be between 0 and 11'),
    body('weightLbs').optional().isFloat({ min: 0 }).withMessage('Weight must be a positive number'),
    body('sex').optional().isIn(['male', 'female', 'unknown']).withMessage('Invalid sex value'),
    body('isNeutered').optional().isBoolean(),
    body('medicalHistory').optional().isString(),
    body('allergies').optional().isString(),
    body('currentMedications').optional().isString()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const {
        id: clientId,
        name,
        breed,
        ageYears,
        ageMonths,
        weightLbs,
        sex,
        isNeutered,
        medicalHistory,
        allergies,
        currentMedications
      } = req.body;

      const newDog = {
        user_id: userId,
        name,
        ...(clientId && { id: clientId }),
        breed: breed || null,
        age_years: ageYears || null,
        age_months: ageMonths || null,
        weight_lbs: weightLbs || null,
        sex: sex || null,
        is_neutered: isNeutered !== undefined ? isNeutered : null,
        medical_history: medicalHistory || null,
        allergies: allergies || null,
        current_medications: currentMedications || null
      };

      const { data: dog, error } = await supabase
        .from('dogs')
        .insert([newDog])
        .select()
        .single();

      if (error) {
        throw new Error('Failed to create dog profile');
      }

      res.status(201).json({
        success: true,
        dog
      });
    } catch (error) {
      console.error('Create dog error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to create dog profile',
        message: error.message
      });
    }
  }
);

/**
 * PUT /api/dogs/:id
 * Update a dog profile
 */
router.put('/:id',
  authenticateToken,
  [
    body('name').optional().notEmpty().withMessage('Dog name cannot be empty'),
    body('breed').optional().isString(),
    body('ageYears').optional().isInt({ min: 0 }).withMessage('Age years must be a positive integer'),
    body('ageMonths').optional().isInt({ min: 0, max: 11 }).withMessage('Age months must be between 0 and 11'),
    body('weightLbs').optional().isFloat({ min: 0 }).withMessage('Weight must be a positive number'),
    body('sex').optional().isIn(['male', 'female', 'unknown']).withMessage('Invalid sex value'),
    body('isNeutered').optional().isBoolean(),
    body('medicalHistory').optional().isString(),
    body('allergies').optional().isString(),
    body('currentMedications').optional().isString()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const dogId = req.params.id;
      const {
        name,
        breed,
        ageYears,
        ageMonths,
        weightLbs,
        sex,
        isNeutered,
        medicalHistory,
        allergies,
        currentMedications
      } = req.body;

      const { data: existingDog, error: checkError } = await supabase
        .from('dogs')
        .select('id')
        .eq('id', dogId)
        .eq('user_id', userId)
        .single();

      if (checkError || !existingDog) {
        return res.status(404).json({ error: 'Dog not found' });
      }

      const updates = {};
      if (name !== undefined) updates.name = name;
      if (breed !== undefined) updates.breed = breed;
      if (ageYears !== undefined) updates.age_years = ageYears;
      if (ageMonths !== undefined) updates.age_months = ageMonths;
      if (weightLbs !== undefined) updates.weight_lbs = weightLbs;
      if (sex !== undefined) updates.sex = sex;
      if (isNeutered !== undefined) updates.is_neutered = isNeutered;
      if (medicalHistory !== undefined) updates.medical_history = medicalHistory;
      if (allergies !== undefined) updates.allergies = allergies;
      if (currentMedications !== undefined) updates.current_medications = currentMedications;

      if (Object.keys(updates).length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }

      const { data: dog, error } = await supabase
        .from('dogs')
        .update(updates)
        .eq('id', dogId)
        .select()
        .single();

      if (error) {
        throw new Error('Failed to update dog profile');
      }

      res.status(200).json({
        success: true,
        dog
      });
    } catch (error) {
      console.error('Update dog error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to update dog profile',
        message: error.message
      });
    }
  }
);

/**
 * DELETE /api/dogs/:id
 * Delete (soft delete) a dog profile
 */
router.delete('/:id',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;
      const dogId = req.params.id;

      const { data: existingDog, error: checkError } = await supabase
        .from('dogs')
        .select('id')
        .eq('id', dogId)
        .eq('user_id', userId)
        .single();

      if (checkError || !existingDog) {
        return res.status(404).json({ error: 'Dog not found' });
      }

      const { error } = await supabase
        .from('dogs')
        .update({ is_active: false })
        .eq('id', dogId);

      if (error) {
        throw new Error('Failed to delete dog profile');
      }

      res.status(200).json({
        success: true,
        message: 'Dog profile deleted successfully'
      });
    } catch (error) {
      console.error('Delete dog error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to delete dog profile',
        message: error.message
      });
    }
  }
);

module.exports = router;
