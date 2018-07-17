import qbs
import qbs.File
import qbs.FileInfo
import qbs.TextFile

/**
  This module generates 'Doxyfile' artifact, which can be used by Doxygen tool to generate documentation.
  */
Module {
	property bool generateRedirectionFile: false

	/**
	  Whether to use input filter. If this property is set to true a _sed_
	  script will be used for _Doxygen_ `INPUT_FILTER`. This script appends
	  `index.html` to Markdown links which end with slash (/). This is required
	  for offline documentation. Web browser won't load index.html` without the
	  aid of HTTP.
	  */
	property bool useInputFilter: true

	additionalProductTypes: ["Doxyfile"]

	FileTagger {
		patterns: ["*.qbs"]
		fileTags: ["qbs"]
	}

	Rule {
		inputs: ['qbs']

		prepare: {
			var doxCmd = new JavaScriptCommand();
			doxCmd.description = 'generating ' + product.sourceDirectory + '/cutehmi.doxygen.Doxyfile'
			doxCmd.highlight = 'codegen';
			doxCmd.sourceCode = function() {
				console.info('Regenerating file ' + product.sourceDirectory + '/cutehmi.doxygen.Doxyfile')

				var docDir = project.sourceDirectory + '/doc/Doxygen/docs'
//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
				// To make relative links work properly first directory of the product location has to be stripped (e.g., 'cutehmi_1' instead of 'modules/cutehmi_1').
				var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory).split('/').slice(1).join('/') // Absolute.
				// Instead of:
				// var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory) // Absolute.
//</workaround>
				var doxygenOptions = {
					'PROJECT_NAME': product.vendor + ' - ' + product.friendlyName + ' (' + product.name + ')',
					'PROJECT_NUMBER': product.major + '.' + product.minor + '.' + product.micro,
					'PROJECT_LOGO': 'doc/project_logo.png',
					'OUTPUT_DIRECTORY': FileInfo.relativePath(product.sourceDirectory, outputDir),
					'HTML_OUTPUT': '.',
					'HTML_DYNAMIC_MENUS': false,
					'ALWAYS_DETAILED_SEC': true,
					'JAVADOC_AUTOBRIEF': true,
					'EXTRACT_ALL': true,
					'INPUT': '.',
					'RECURSIVE': true,
					'USE_MDFILE_AS_MAINPAGE': 'README.md',
					'GENERATE_LATEX': false,
					'GENERATE_TREEVIEW': true,
					'QUIET': true,
					'GENERATE_TAGFILE': 'doxygen.tag',
					'INPUT_FILTER' : product.cutehmi.doxygen.useInputFilter ? 'sed \'s/\\(\\[[[:alnum:][:blank:]\\/.:_@#-]*\\]([[:alnum:]\\/.:_@#-]*\\/\\)\\()\\)/\\1index.html\\2/g\'' : '',
					'ALIASES': ['principle{1}=\\xrefitem principles \\"Principle\\" \\"Principles\\" \\b \\"\\1\\" \\n',
								'threadsafe=\\remark This method is thread-safe.'
					],
					'MACRO_EXPANSION': true,
					'EXPAND_ONLY_PREDEF': true,
					'PREDEFINED': ['DOXYGEN_WORKAROUND',
								   'Q_DECLARE_TR_FUNCTIONS()=',
								   'QT_RCC_MANGLE_NAMESPACE()='
					],
					'LAYOUT_FILE': '../../doc/layout/ProductLayout.xml',
					'SHOW_FILES': false,
					'SHOW_USED_FILES': false
				}

//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
				// Doxygen is not able to create whole path recursively (like mkidr -p does) and quits with error, so let's create it for him.
				if (!File.exists(outputDir)) {
					console.info("Creating directory " + outputDir)
					File.makePath(outputDir)
				}
//</workaround>

				var f = new TextFile(product.sourceDirectory + "/cutehmi.doxygen.Doxyfile", TextFile.WriteOnly);
				try {
					f.writeLine("# This file has been autogenerated by Qbs cutehmi.doxygen module.")
					for (var option in doxygenOptions) {
						var val = doxygenOptions[option]
						if (typeof val === 'string')
							val = '"' + val + '"'
						else if (typeof val === 'boolean') {
							if (val)
								val = 'YES'
							else
								val = 'NO'
						}
						if (Array.isArray(val)) {
							for (var i = 0; i < val.length; i++)
								f.writeLine(option + ' += "' + val[i] + '"')
						} else
							f.writeLine(option + ' = ' + val)
					}

					// Append Qt '.tags' files to TAGILES.
					for (var qtSubmodule in product.Qt) {
						var docSubmoduleName = 'qt' + qtSubmodule;	// Names of Qt modules in 'C:/Qt/Docs' directory start with 'qt' prefix (this applies to directories and '.tags' files).
						f.writeLine('TAGFILES += ' + product.Qt.core.docPath + '/' + docSubmoduleName + '/' + docSubmoduleName + '.tags'
									+ '=http://doc.qt.io/qt-' + product.Qt.core.versionMajor)
					}

					// Append '.tags' files to TAGFILES from dependencies.
					for (i in product.dependencies) {
						var dependency = product.dependencies[i]
						if ('cutehmi' in dependency && 'doxygen' in dependency.cutehmi) {
//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
							// To make relative links work properly first directory of the product location has to be stripped (e.g., 'cutehmi_1' instead of 'modules/cutehmi_1').
							var dependencyOutputDir = docDir + '/' + FileInfo.relativePath(project.sourceDirectory, dependency.sourceDirectory).split('/').slice(1).join('/') // Absolute.
							// Instead of:
							// var dependencyOutputDir = docDir + '/' + FileInfo.relativePath(project.sourceDirectory, dependency.sourceDirectory).split('/') // Absolute.
//</workaround>
							var tagLoc = FileInfo.relativePath(product.sourceDirectory, dependency.sourceDirectory) + '/doxygen.tag'
							var htmlLoc = FileInfo.relativePath(outputDir, dependencyOutputDir)
							f.writeLine('TAGFILES += ' + '"' +  tagLoc + ' = ' + htmlLoc + '"')
						}
					}
				} finally {
					f.close()
				}
			}

			if (!product.cutehmi.doxygen.generateRedirectionFile)
				return [doxCmd]
			else {
				var indexCmd = new JavaScriptCommand();
				indexCmd.description = 'generating ' + product.sourceDirectory + '/index.html'
				indexCmd.highlight = 'codegen';
				indexCmd.sourceCode = function() {
					var docDir = project.sourceDirectory + '/doc/Doxygen/docs'
//<workaround id="qbs-cutehmi-doxygen-2" target="Doxygen" cause="missing">
					// To make relative links work properly first directory of the product location has to be stripped (e.g., 'cutehmi_1' instead of 'modules/cutehmi_1').
					var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory).split('/').slice(1).join('/') // Absolute.
					// Instead of:
					// var outputDir = docDir +  '/' + FileInfo.relativePath(project.sourceDirectory, product.sourceDirectory) // Absolute.
//</workaround>
					var href = FileInfo.relativePath(product.sourceDirectory, outputDir) + '/index.html'
					console.info('Regenerating file ' + product.sourceDirectory + '/index.html')
					var f = new TextFile(product.sourceDirectory + "/index.html", TextFile.WriteOnly);
					try {
						f.writeLine('<!DOCTYPE html>')
						f.writeLine('<!-- This file has been autogenerated by Qbs cutehmi.doxygen module. -->')
						f.writeLine('<html lang="en">')
						f.writeLine('  <head>')
						f.writeLine('    <meta http-equiv="refresh" content="0; URL=\'' + href + '\'" />')
						f.writeLine('    <meta charset="utf-8">')
						f.writeLine('    <title>Redirecting to documentation</title>')
						f.writeLine('  </head>')
						f.writeLine('  <body>')
						f.writeLine('     If you haven\'t been redirected automatically click the following <a href="' + href + '">link</a>.')
						f.writeLine('  </body>')
						f.writeLine('</html>')
					} finally {
						f.close()
					}
				}
				return [doxCmd, indexCmd]
			}
		}

		outputArtifacts: product.cutehmi.doxygen.generateRedirectionFile ? [{ filePath: product.sourceDirectory + '/cutehmi.doxygen.Doxyfile', fileTags: ["Doxyfile"] },
																			{ filePath: product.sourceDirectory + '/index.html', fileTags: ["html"] }]
																		 : [{ filePath: product.sourceDirectory + '/cutehmi.doxygen.Doxyfile', fileTags: ["Doxyfile"] }]
		outputFileTags: ["Doxyfile", "html"]
	}
}

//(c)MP: Copyright © 2018, Michal Policht. All rights reserved.
//(c)MP: This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
