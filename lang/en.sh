# lang/en.sh
T=()

T[MENU_TITLE]="ICARUS SERVER MANAGER"
T[MENU_START]="START server"
T[MENU_STOP]="STOP server"
T[MENU_RESTART]="RESTART server"
T[MENU_STATUS]="STATUS"
T[MENU_LOGS]="VIEW SERVER LOGS (container)"
T[MENU_BACKUP]="BACKUP world"
T[MENU_RESTORE]="RESTORE backup"
T[MENU_SETTINGS]="EDIT SETTINGS"
T[MENU_LANG]="LANGUAGE"
T[MENU_EXIT]="EXIT"

T[SELECT_OPTION]="Select option"
T[PRESS_ENTER]="Press Enter to return to menu"
T[PRESS_ENTER_GENERIC]="Press Enter..."
T[EXITING]="Exiting."
T[INVALID_OPTION]="Invalid option."

T[WAITING]="Waiting for server to start..."
T[RUNNING]="Server is RUNNING."
T[TIMEOUT]="Timeout reached. Server did not start correctly."

T[STOPPED]="Server stopped."

T[CONTAINER_NOT_FOUND]="Container 'icarus-dedicated' not found."
T[TIP_START_FIRST]="Tip: start the server first."
T[LOGS_HINT]="Showing container logs (Ctrl+C to return to menu)"
T[LOGS_NOT_RUNNING]="Container is not running. Showing last logs:"

T[ENV_NOT_FOUND]="ENV file not found"
T[ENV_CREATE_HINT]="Create it first, e.g."
T[ENV_CURRENT]="Current .env"

T[SETTINGS_TITLE]="ICARUS SETTINGS"
T[SET_SERVERNAME]="Change SERVERNAME"
T[SET_JOINPASS]="Change JOIN_PASSWORD"
T[SET_ADMINPASS]="Change ADMIN_PASSWORD"
T[SET_SHOW]="Show current settings"
T[SET_APPLY]="Apply changes (restart server)"
T[BACK]="Back"

T[SERVERNAME_LABEL]="SERVERNAME (visible server name):"
T[JOINPASS_LABEL]="JOIN_PASSWORD (players password):"
T[ADMINPASS_LABEL]="ADMIN_PASSWORD (admin password):"

T[APPLY_REQUIRES_RESTART]="Applying changes requires restart."
T[RESTART_NOW]="Restart server now? (y/n)"

T[CURRENT]="Current"
T[NEW_VALUE]="New value (leave empty = keep current)"
T[SAVED]="Saved"
T[UPDATED]="updated"
T[NO_CHANGE]="No change"

T[BACKUP_STOPPING_FOR_CONSISTENCY]="Server is running. Stopping it for consistent backup..."
T[BACKUP_CREATING]="Creating backup:"
T[BACKUP_VOLUME]="Volume"
T[BACKUP_OUTPUT]="Output"
T[BACKUP_CREATED]="Backup created successfully."
T[BACKUP_FAILED]="Backup FAILED."
T[START_NOW]="Start server now? (y/n)"

T[NO_BACKUPS]="No backups found in"
T[RESTORE_AVAILABLE]="Available backups:"
T[RESTORE_SELECT]="Select backup number to restore (or 0 to cancel)"
T[RESTORE_INVALID]="Invalid selection."
T[CANCELLED]="Cancelled."
T[RESTORE_YOU_ARE_ABOUT]="You are about to RESTORE:"
T[RESTORE_WARNING]="WARNING: This will overwrite the current world data in the Docker volume."
T[RESTORE_CONFIRM]="Type YES to continue"
T[RESTORE_STOPPING]="Stopping server..."
T[RESTORE_TO_VOL]="Restoring to volume"
T[RESTORE_DONE]="Restore completed successfully."
T[RESTORE_FAILED]="Restore FAILED."

T[CANNOT_CD]="Cannot cd to"

T[LANG_TITLE]="LANGUAGE"
T[LANG_OPT_EN]="English"
T[LANG_OPT_PL]="Polish"
T[LANG_SAVED]="Language saved."
