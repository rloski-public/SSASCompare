# DAXComparison

# Define the root path of the current module
$ModuleRoot = $PSScriptRoot

# Define paths to public and private function directories
$PublicFunctionsPath = Join-Path -Path $ModuleRoot -ChildPath "Public"
$PrivateFunctionsPath = Join-Path -Path $ModuleRoot -ChildPath "Private"

# Get all .ps1 files in the Public and Private directories
$PublicFunctionFiles = Get-ChildItem -Path $PublicFunctionsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$PrivateFunctionFiles = Get-ChildItem -Path $PrivateFunctionsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

# Dot-source all found function files
foreach ($file in $PublicFunctionFiles + $PrivateFunctionFiles) {
    try {
        . $file.FullName
        Write-Verbose "Successfully loaded function file: $($file.Name)"
    }
    catch {
        Write-Error "Failed to load function file $($file.Name): $_"
    }
}

# Export public functions so they are available to the user
# This assumes your public functions are defined in files within the 'Public' directory
# and the function name matches the file's base name (e.g., Get-MyData.ps1 defines Get-MyData)
$FunctionsToExport = $PublicFunctionFiles | Select-Object -ExpandProperty BaseName
Export-ModuleMember -Function $FunctionsToExport -ErrorAction SilentlyContinue
