-- Migration: Add RPC function for knowledge base vector similarity search
-- This function is used by the RAG system to find relevant pet health information

-- Create the match_knowledge_base function for vector similarity search
CREATE OR REPLACE FUNCTION match_knowledge_base(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 5
)
RETURNS TABLE (
    id uuid,
    category varchar(100),
    title varchar(255),
    content text,
    source varchar(255),
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kb.id,
        kb.category,
        kb.title,
        kb.content,
        kb.source,
        1 - (kb.embedding <=> query_embedding) as similarity
    FROM ai_knowledge_base kb
    WHERE kb.is_verified = true
        AND 1 - (kb.embedding <=> query_embedding) > match_threshold
    ORDER BY kb.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION match_knowledge_base(vector(1536), float, int) TO authenticated;

COMMENT ON FUNCTION match_knowledge_base IS 'Searches the AI knowledge base using vector similarity to find relevant pet health information for RAG';
