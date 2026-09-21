# Changelog
All notable changes to this project will be documented in this file.

## Release 2.1.1

### Bugfix
- Updated legacy UI bindings
- Fix TDC-X issue

## Release 2.1.0

### New features
- Check if persistent data to load provides all relevant parameters. Otherwise add default values

### Improvements
- Better instance handling regarding FlowConfig

### Bugfix
- Legacy bindings of ValueDisplay elements within UI did not work if deployed with VS Code AppSpace SDK
- UI differs if deployed via Appstudio or VS Code AppSpace SDK
- Fullscreen icon of iFrame was visible

## Release 2.0.0

### New features
- Supports FlowConfig feature to provide received messages / to send content to TCP/IP client
- Provide version of module via 'OnNewStatusModuleVersion'
- Function 'getParameters' to provide PersistentData parameters
- Check if features of module can be used on device and provide this via 'OnNewStatusModuleIsActive' event / 'getStatusModuleActive' function
- Function to 'resetModule' to default setup

### Improvements
- 'setSelectedClientWhitelist' and 'setSelectedClientBroadcast' return success of function
- Update selected whitelist / broadcast if instance was changed
- New UI design available (e.g. selectable via CSK_Module_PersistentData v4.1.0 or higher), see 'OnNewStatusCSKStyle'
- Check if instance exists if selected
- 'loadParameters' returns its success
- 'sendParameters' can control if sent data should be saved directly by CSK_Module_PersistentData
- Added UI icon

### Bugfix
- Error if module is not active but 'getInstancesAmount' was called
- Error if trying to deregister from broadcast
- transmitDataNUM did not work after deregistering from event to forward data
- No reset of selected whitelist / broadcast after loading new parameters

## Release 1.0.0
- Initial commit
