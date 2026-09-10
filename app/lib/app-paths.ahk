ResolveConfigPath(scriptDir, appDataDir, isCompiled, portableMarkerExists) {
    if !isCompiled || portableMarkerExists {
        return scriptDir "\awful-cases.ini"
    }
    return appDataDir "\Awful Cases\awful-cases.ini"
}
