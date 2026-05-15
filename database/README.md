# Digzopian Sovereignty Database

PostgreSQL database setup for the digzopian sovereignty brand and workflows.

## Quick Start

### Prerequisites
- PostgreSQL 14+ installed
- VS Code with SQLTools extension
- SQLTools PostgreSQL driver

### Setup Steps

1. **Open the workspace**
   ```bash
   code "digzopian-sovereignty.code-workspace"
   ```

2. **Start PostgreSQL** (if not running)
   ```bash
   pg_ctl -D /path/to/data start
   ```

3. **Run the schema**
   - Open `database/schema.sql` in VS Code
   - Use SQLTools to execute against your PostgreSQL server

4. **Connect SQLTools**
   - Press `Ctrl+Shift+P` → "SQLTools: Connect"

    - For **local**: Select "Digzopian Sovereignty - PostgreSQL"
    - For **cloud** (Azure, AWS, etc): Select "Digzopian Sovereignty - PostgreSQL (Cloud)"
    - Enter your PostgreSQL password when prompted

#### Cloud Connection Example

Edit the workspace file or SQLTools settings with your cloud provider details:

```
{
   "name": "Digzopian Sovereignty - PostgreSQL (Cloud)",
   "driver": "PostgreSQL",
   "server": "<your-cloud-host>.postgres.database.azure.com",
   "port": 5432,
   "database": "digzopian_sovereignty",
   "username": "<your-cloud-username>",
   "askForPassword": true,
   "connectionTimeout": 15,
   "ssl": true
}
```

Replace `<your-cloud-host>` and `<your-cloud-username>` with your actual cloud database details.

## Database Structure

| Table | Purpose |
|-------|---------|
| `entity_registry` | Core entity tracking |
| `workflow_states` | Workflow state management |
| `sovereignty_audit` | Audit trail for all actions |

## SQL Snippets

Use these shortcuts in SQLTools:
- `ds-entities` - List active entities
- `ds-workflows` - Get workflow status
- `ds-audit` - View audit trail
- `ds-entity-stats` - Entity statistics
- `ds-health` - Database health check

## Brand Configuration

The digzopian sovereignty brand includes:
- Custom metadata structure with brand fields
- Sovereignty levels (1-3) for entity management
- Full audit trail for compliance
- Workflow state tracking

## Support

For digzopian sovereignty database support, refer to the main project documentation.