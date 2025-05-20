$pluginPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\app_links-6.4.0\android\build.gradle"
$content = Get-Content $pluginPath
$newContent = $content -replace "classpath 'com.android.tools.build:gradle:8.5.2'", "classpath 'com.android.tools.build:gradle:7.3.0'"
$newContent | Set-Content $pluginPath
Write-Host "Updated the Gradle version in app_links plugin" 