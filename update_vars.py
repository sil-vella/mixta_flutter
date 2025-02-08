import yaml
import re
import os

# Define ProjLevelVars values
proj_vars = {
    "appName": "flutter_base_two",
    "appDescription": "Flutter Base Two.",
    "appVersion": "1.0.0",
    "buildNumber": 1,
    "kotlinVersion": "1.9.0",
    "androidGradlePluginVersion": "8.6.0",
    "splashColor": "#ffffff",
    "splashImagePath": "assets/images/splash_002.png",
    "launcherIconPath": "assets/images/icon_002_final.png",
    "adaptiveIconBackground": "assets/images/icon_002_background_final.png",
    "adaptiveIconForeground": "assets/images/icon_002_foreground_final.png",
    "assetPaths": [
        "assets/audio/",
        "assets/config/",
        "assets/images/"
    ]
}

# Paths to the configuration files
PUBSPEC_PATH = "pubspec.yaml"
BUILD_GRADLE_PATH = "android/build.gradle"


def update_pubspec(pubspec_path):
    """Update or create pubspec.yaml with the project variables."""
    if not os.path.exists(pubspec_path):
        print(f"Error: {pubspec_path} not found!")
        return

    with open(pubspec_path, "r") as file:
        pubspec = yaml.safe_load(file)

    # Update pubspec.yaml
    pubspec["name"] = proj_vars["appName"]
    pubspec["description"] = proj_vars["appDescription"]
    pubspec["version"] = f"{proj_vars['appVersion']}+{proj_vars['buildNumber']}"

    # Update or add flutter_native_splash configuration
    if "flutter_native_splash" not in pubspec:
        pubspec["flutter_native_splash"] = {}
    pubspec["flutter_native_splash"]["color"] = proj_vars["splashColor"]
    pubspec["flutter_native_splash"]["image"] = proj_vars["splashImagePath"]

    # Update or add flutter_launcher_icons configuration
    if "flutter_launcher_icons" not in pubspec:
        pubspec["flutter_launcher_icons"] = {}
    pubspec["flutter_launcher_icons"]["image_path"] = proj_vars["launcherIconPath"]
    pubspec["flutter_launcher_icons"]["adaptive_icon_background"] = proj_vars["adaptiveIconBackground"]
    pubspec["flutter_launcher_icons"]["adaptive_icon_foreground"] = proj_vars["adaptiveIconForeground"]

    # Update or add assets
    if "flutter" not in pubspec:
        pubspec["flutter"] = {}
    pubspec["flutter"]["assets"] = proj_vars["assetPaths"]

    # Write updated content back to pubspec.yaml
    with open(pubspec_path, "w") as file:
        yaml.dump(pubspec, file, default_flow_style=False)

    print(f"Updated {pubspec_path} with project variables.")


def update_build_gradle(build_gradle_path):
    """Update or create build.gradle with the project variables."""
    if not os.path.exists(build_gradle_path):
        print(f"Error: {build_gradle_path} not found!")
        return

    with open(build_gradle_path, "r") as file:
        gradle_content = file.read()

    # Define replacements
    replacements = {
        r"ext\.kotlin_version = .+": f"ext.kotlin_version = '{proj_vars['kotlinVersion']}'",
        r"classpath 'com\.android\.tools\.build:gradle:.+'": f"classpath 'com.android.tools.build:gradle:{proj_vars['androidGradlePluginVersion']}'",
        r'classpath "org\.jetbrains\.kotlin:kotlin-gradle-plugin:.+"': f'classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:{proj_vars["kotlinVersion"]}"',
    }

    # Update gradle content
    for pattern, replacement in replacements.items():
        if re.search(pattern, gradle_content):
            gradle_content = re.sub(pattern, replacement, gradle_content)
        else:
            # Add missing lines if not found
            if "ext.kotlin_version" in replacement:
                gradle_content = f"buildscript {{\n    {replacement}\n}}" + gradle_content
            else:
                gradle_content = re.sub(r"dependencies \{", f"dependencies {{\n        {replacement}", gradle_content)

    # Write updated content back to build.gradle
    with open(build_gradle_path, "w") as file:
        file.write(gradle_content)

    print(f"Updated {build_gradle_path} with project variables.")


# Run updates
update_pubspec(PUBSPEC_PATH)
update_build_gradle(BUILD_GRADLE_PATH)
