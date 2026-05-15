-- ============================================
-- DIGZOPIAN SOVEREIGNTY SQL SNIPPETS
-- Custom SQL snippets for digzopian sovereignty workflows
-- ============================================

-- Snippet: ds-entities - List all active entities
-- Lists all active entities in the sovereignty system
SELECT 
    entity_id,
    entity_name,
    entity_type,
    sovereignty_level,
    status,
    created_at,
    updated_at
FROM entity_registry
WHERE status = 'active'
ORDER BY sovereignty_level DESC, entity_name;

-- Snippet: ds-workflows - Get workflow status
-- Shows current workflow states and counts
SELECT 
    workflow_type,
    current_state,
    COUNT(*) as count,
    MIN(created_at) as started,
    MAX(CASE WHEN completed_at IS NOT NULL THEN completed_at END) as completed
FROM workflow_states
GROUP BY workflow_type, current_state
ORDER BY workflow_type, current_state;

-- Snippet: ds-audit - Get recent audit entries
-- Shows recent sovereignty audit trail
SELECT 
    audit_id,
    action_type,
    actor,
    timestamp,
    status,
    action_details->>'description' as description
FROM sovereignty_audit
ORDER BY timestamp DESC
LIMIT 50;

-- Snippet: ds-create-entity - Create new sovereignty entity
-- Template for creating new entities
INSERT INTO entity_registry (entity_name, entity_type, sovereignty_level, metadata)
VALUES ('{{entity_name}}', '{{entity_type}}', {{sovereignty_level}}, '{{metadata}}'::jsonb)
RETURNING entity_id, entity_name, created_at;

-- Snippet: ds-update-state - Update workflow state
-- Template for updating workflow states
UPDATE workflow_states
SET previous_state = current_state,
    current_state = '{{new_state}}',
    updated_at = CURRENT_TIMESTAMP
WHERE workflow_id = '{{workflow_id}}'
RETURNING workflow_id, previous_state, current_state;

-- Snippet: ds-log-action - Log sovereignty action
-- Template for logging actions
SELECT log_sovereignty_action(
    '{{action_type}}',
    '{{actor}}',
    '{{target_entity}}'::uuid,
    '{{action_details}}'::jsonb
);

-- Snippet: ds-entity-stats - Get entity statistics
-- Shows sovereignty level distribution
SELECT 
    sovereignty_level,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM entity_registry
WHERE status = 'active'
GROUP BY sovereignty_level
ORDER BY sovereignty_level;

-- Snippet: ds-health - Database health check
-- Quick health check for sovereignty database
SELECT 
    'Entities' as metric, COUNT(*) as value FROM entity_registry
    UNION ALL
SELECT 'Active Workflows', COUNT(*) FROM workflow_states WHERE completed_at IS NULL
    UNION ALL
SELECT 'Audit Entries', COUNT(*) FROM sovereignty_audit
    UNION ALL
SELECT 'Database Size', pg_size_pretty(pg_database_size(current_database()));