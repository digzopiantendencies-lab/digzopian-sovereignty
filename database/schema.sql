-- Digzopian Sovereignty Database Schema
-- PostgreSQL Database Setup

-- Create the main sovereignty database
CREATE DATABASE digzopian_sovereignty;

-- Connect to the database
\c digzopian_sovereignty;

-- ============================================
-- SOVEREIGNTY CORE TABLES
-- ============================================

-- Entity registry for sovereignty tracking
CREATE TABLE IF NOT EXISTS entity_registry (
    entity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_name VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    sovereignty_level INTEGER DEFAULT 1,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Workflow state management
CREATE TABLE IF NOT EXISTS workflow_states (
    workflow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_name VARCHAR(255) NOT NULL,
    workflow_type VARCHAR(100) NOT NULL,
    current_state VARCHAR(100) NOT NULL,
    previous_state VARCHAR(100),
    entity_id UUID REFERENCES entity_registry(entity_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    state_data JSONB DEFAULT '{}'::jsonb
);

-- Audit trail for sovereignty actions
CREATE TABLE IF NOT EXISTS sovereignty_audit (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type VARCHAR(100) NOT NULL,
    actor VARCHAR(255) NOT NULL,
    target_entity UUID REFERENCES entity_registry(entity_id),
    action_details JSONB DEFAULT '{}'::jsonb,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    status VARCHAR(50) DEFAULT 'completed'
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_entity_type ON entity_registry(entity_type);
CREATE INDEX idx_entity_status ON entity_registry(status);
CREATE INDEX idx_workflow_entity ON workflow_states(entity_id);
CREATE INDEX idx_workflow_state ON workflow_states(current_state);
CREATE INDEX idx_audit_timestamp ON sovereignty_audit(timestamp DESC);
CREATE INDEX idx_audit_actor ON sovereignty_audit(actor);

-- ============================================
-- FUNCTIONS FOR SOVEREIGNTY OPERATIONS
-- ============================================

-- Function to update timestamp on row modification
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for automatic timestamp updates
CREATE TRIGGER update_entity_timestamp
    BEFORE UPDATE ON entity_registry
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to log sovereignty actions
CREATE OR REPLACE FUNCTION log_sovereignty_action(
    p_action_type VARCHAR,
    p_actor VARCHAR,
    p_target_entity UUID,
    p_action_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_audit_id UUID;
BEGIN
    INSERT INTO sovereignty_audit (action_type, actor, target_entity, action_details)
    VALUES (p_action_type, p_actor, p_target_entity, p_action_details)
    RETURNING audit_id INTO v_audit_id;
    RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS FOR SOVEREIGNTY DASHBOARD
-- ============================================

-- View for active entities summary
CREATE OR REPLACE VIEW v_active_entities AS
SELECT 
    entity_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN sovereignty_level = 1 THEN 1 END) as level_1_count,
    COUNT(CASE WHEN sovereignty_level = 2 THEN 1 END) as level_2_count,
    COUNT(CASE WHEN sovereignty_level = 3 THEN 1 END) as level_3_count
FROM entity_registry
WHERE status = 'active'
GROUP BY entity_type;

-- View for workflow status
CREATE OR REPLACE VIEW v_workflow_status AS
SELECT 
    workflow_type,
    current_state,
    COUNT(*) as workflow_count,
    MIN(created_at) as earliest_start,
    MAX(created_at) as latest_update
FROM workflow_states
GROUP BY workflow_type, current_state;

-- ============================================
-- INITIAL DATA SEED
-- ============================================

INSERT INTO entity_registry (entity_name, entity_type, sovereignty_level, status, metadata)
VALUES 
    ('Digzopian Core', 'system', 3, 'active', '{"brand": "digzopian", "tier": "core"}'::jsonb),
    ('Sovereignty Engine', 'service', 3, 'active', '{"brand": "digzopian", "component": "engine"}'::jsonb),
    ('Workflow Manager', 'service', 2, 'active', '{"brand": "digzopian", "component": "workflow"}'::jsonb),
    ('Audit System', 'service', 2, 'active', '{"brand": "digzopian", "component": "audit"}'::jsonb);

COMMENT ON DATABASE digzopian_sovereignty IS 'Digzopian Sovereignty Brand Database - Core data management for sovereignty workflows';