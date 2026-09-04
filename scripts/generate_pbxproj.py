#!/usr/bin/env python3
"""
PixelV2 - Xcode Project Generator
Gaara Quantum Studio
Genera PixelV2.xcodeproj completo para compilación en GitHub Actions o local Mac.
"""

import os
import uuid
from pathlib import Path

def gen_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    script_dir = Path(__file__).resolve().parent
    app_root = script_dir.parent
    proj_dir = app_root / "PixelV2.xcodeproj"
    proj_dir.mkdir(exist_ok=True)
    xcshared = proj_dir / "xcshareddata" / "xcschemes"
    xcshared.mkdir(exist_ok=True, parents=True)

    files = [
        # Swift source files
        ('App/App.swift', 'App.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/KeyManager.swift', 'KeyManager.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/ContainerManager.swift', 'ContainerManager.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/ModEngine.swift', 'ModEngine.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/ModStateStore.swift', 'ModStateStore.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Theme.swift', 'Theme.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Components/GlowingWaveView.swift', 'GlowingWaveView.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Components/PixelLogoView.swift', 'PixelLogoView.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Views/KeyAuthView.swift', 'KeyAuthView.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Views/PixelDashboardView.swift', 'PixelDashboardView.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Views/ContainerExplorerView.swift', 'ContainerExplorerView.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Views/SettingsView.swift', 'SettingsView.swift', 'source', 'PBXSourcesBuildPhase'),
        ('App/UI/Views/MainTabView.swift', 'MainTabView.swift', 'source', 'PBXSourcesBuildPhase'),
        # C / Objective-C source files
        ('App/Core/bad_query.c', 'bad_query.c', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/bad_query.h', 'bad_query.h', 'header', None),
        ('App/Core/MCMLease.m', 'MCMLease.m', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/MCMLease.h', 'MCMLease.h', 'header', None),
        ('App/Core/InjectionEngine.m', 'InjectionEngine.m', 'source', 'PBXSourcesBuildPhase'),
        ('App/Core/InjectionEngine.h', 'InjectionEngine.h', 'header', None),
        ('App/Bridge/mcm_bridge.m', 'mcm_bridge.m', 'source', 'PBXSourcesBuildPhase'),
        ('App/Bridge/mcm_bridge.h', 'mcm_bridge.h', 'header', None),
        ('App/Bridge/PixelV2-Bridging-Header.h', 'PixelV2-Bridging-Header.h', 'header', None),
        # Resources & configs
        ('App/Assets.xcassets', 'Assets.xcassets', 'resource', 'PBXResourcesBuildPhase'),
        ('App/Info.plist', 'Info.plist', 'plist', None),
        ('App/PixelV2.entitlements', 'PixelV2.entitlements', 'plist', None)
    ]

    file_entries = []
    for path, name, ftype, phase in files:
        fid = gen_id()
        bid = gen_id() if phase else None
        file_entries.append({
            'fid': fid,
            'bid': bid,
            'path': path,
            'name': name,
            'ftype': ftype,
            'phase': phase
        })

    proj_id = gen_id()
    target_id = gen_id()
    sources_phase_id = gen_id()
    resources_phase_id = gen_id()
    frameworks_phase_id = gen_id()
    main_group_id = gen_id()
    products_group_id = gen_id()
    product_ref_id = gen_id()
    build_config_list_id = gen_id()
    target_config_list_id = gen_id()
    debug_config_proj_id = gen_id()
    release_config_proj_id = gen_id()
    debug_config_target_id = gen_id()
    release_config_target_id = gen_id()

    pbx = f'''// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
'''

    for f in file_entries:
        if f['bid']:
            pbx += f'''\t\t{f['bid']} /* {f['name']} in {f['phase']} */ = {{isa = PBXBuildFile; fileRef = {f['fid']}; }};\n'''

    pbx += f'''/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{product_ref_id} /* PixelV2.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = PixelV2.app; sourceTree = BUILT_PRODUCTS_DIR; }};
'''

    for f in file_entries:
        file_type = 'sourcecode.swift' if f['name'].endswith('.swift') else (
            'sourcecode.c.c' if f['name'].endswith('.c') else (
                'sourcecode.c.objc' if f['name'].endswith('.m') else (
                    'sourcecode.c.h' if f['name'].endswith('.h') else (
                        'folder.assetcatalog' if f['name'].endswith('.xcassets') else (
                            'text.plist.xml' if f['name'].endswith('.plist') or f['name'].endswith('.entitlements') else 'folder'
                        )
                    )
                )
            )
        )
        pbx += f'''\t\t{f['fid']} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = \"{f['path']}\"; sourceTree = \"<group>\"; }};\n'''

    pbx += f'''/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
'''

    for f in file_entries:
        pbx += f'''\t\t\t\t{f['fid']} /* {f['name']} */,\n'''

    pbx += f'''\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_ref_id} /* PixelV2.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* PixelV2 */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {target_config_list_id} /* Build configuration list for PBXNativeTarget \"PixelV2\" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = PixelV2;
\t\t\tproductName = PixelV2;
\t\t\tproductReference = {product_ref_id} /* PixelV2.app */;
\t\t\tproductType = \"com.apple.product-type.application\";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {build_config_list_id} /* Build configuration list for PBXProject \"PixelV2\" */;
\t\t\tcompatibilityVersion = \"Xcode 14.0\";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = \"\";
\t\t\tprojectRoot = \"\";
\t\t\ttargets = (
\t\t\t\t{target_id} /* PixelV2 */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
'''

    for f in file_entries:
        if f['phase'] == 'PBXResourcesBuildPhase':
            pbx += f'''\t\t\t\t{f['bid']} /* {f['name']} in Resources */,\n'''

    pbx += f'''\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
'''

    for f in file_entries:
        if f['phase'] == 'PBXSourcesBuildPhase':
            pbx += f'''\t\t\t\t{f['bid']} /* {f['name']} in Sources */,\n'''

    pbx += f'''\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_config_proj_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t\"DEBUG=1\",
\t\t\t\t\t\"$(inherited)\",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_proj_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = \"wholemodule\";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_config_target_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = \"\";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = App/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t\"$(inherited)\",
\t\t\t\t\t\"@executable_path/Frameworks\",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 2.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.apple.mobile.MobileHouseArrest;
\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = \"App/Bridge/PixelV2-Bridging-Header.h\";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_target_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = \"\";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = App/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t\"$(inherited)\",
\t\t\t\t\t\"@executable_path/Frameworks\",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 2.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.apple.mobile.MobileHouseArrest;
\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = \"App/Bridge/PixelV2-Bridging-Header.h\";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_config_list_id} /* Build configuration list for PBXProject \"PixelV2\" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config_proj_id} /* Debug */,
\t\t\t\t{release_config_proj_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{target_config_list_id} /* Build configuration list for PBXNativeTarget \"PixelV2\" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config_target_id} /* Debug */,
\t\t\t\t{release_config_target_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {proj_id} /* Project object */;
}}
'''

    pbx_path = proj_dir / "project.pbxproj"
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write(pbx)
    print(f"[OK] Proyecto generado en: {pbx_path}")

    # Scheme
    scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "PixelV2.app"
               BlueprintName = "PixelV2"
               ReferencedContainer = "container:PixelV2.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
</Scheme>'''
    scheme_path = xcshared / "PixelV2.xcscheme"
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write(scheme)
    print(f"[OK] Esquema generado en: {scheme_path}")

if __name__ == "__main__":
    main()
