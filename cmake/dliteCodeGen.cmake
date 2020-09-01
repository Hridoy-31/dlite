# -- Macro simplifying calling dlite-codegen
#
# dlite_codegen(output template url [options])
#
#   Generate source code using dlite-codegen.
#
# Arguments:
#   output
#       Path to generated output file to generate
#   template
#       Name of or path to the template to use
#   url
#       url of entity to generate code for
#   [ENV_OPTIONS options]
#       A comma-separated list of options to dlite-env
#   {options}
#       Additional options to dlite-codegen may be provided after the
#       ordinary arguments.  Relevant options include:
#         --built-in              Whether `url` refers to a built-in instance
#         --build-root            Whether to load plugins from build directory
#         --native-typenames      Whether to generate native typenames
#         --storage-plugins=PATH  Additional paths to look for storage plugins
#         --variables=STRING      Assignment of additional variables as a
#                                 semicolon-separated string of VAR=VALUE pairs
#
# Additional variables that are considered:
#
#   PATH
#       Path with the dlite library, Windows only
#   dlite_LD_LIBRARY_PATH
#       Path with the dlite library, Linux only
#   dlite_STORAGE_PLUGINS
#       Path to needed dlite storage plugins
#   dlite_TEMPLATES
#       Path to template files if `template` is not a path to an existing
#       template file
#   dlite_PATH
#       Path to look for dlite-codegen if it is not a target of the current
#       cmake session

macro(dlite_codegen output template url)

  include(CMakeParseArguments)
  cmake_parse_arguments(CODEGEN "" "ENV_OPTIONS" "" ${ARGN})

  string(REPLACE "," ";" env_options "${CODEGEN_ENV_OPTIONS}")
  set(codegen_dependencies "")
  set(codegen_extra_options ${CODEGEN_UNPARSED_ARGUMENTS})

  if(EXISTS ${template})
    set(template_option --template-file=${template})
    list(APPEND codegen_dependencies ${template})
  else()
    set(template_option --format=${template})
    foreach(dir ${dlite_TEMPLATES})
      if(EXISTS ${dir}/${template}.txt)
        list(APPEND codegen_dependencies "${dir}/${template}.txt")
      endif()
    endforeach()
  endif()

  if(EXISTS ${url})
    list(APPEND codegen_dependencies ${url})
  endif()

  if(TARGET dlite-codegen)
    set(DLITE_CODEGEN $<TARGET_FILE:dlite-codegen>)
    list(APPEND codegen_dependencies dlite dlite-codegen)
    if(WITH_JSON)
      list(APPEND codegen_dependencies dlite-plugins-json)
    endif()
  else()
    find_program(DLITE_CODEGEN
      NAMES dlite-codegen
      PATHS
        ${DLITE_ROOT}/${DLITE_RUNTIME_DIR}
        ${dlite-tools_BINARY_DIR}
        ${dlite_PATH}
      )
    list(APPEND codegen_dependencies ${DLITE_CODEGEN})
  endif()

  if(TARGET dlite-env)
    set(DLITE_ENV $<TARGET_FILE:dlite-env>)
    list(APPEND codegen_dependencies dlite-env)
  else()
    find_program(DLITE_ENV
      NAMES dlite-env
      PATHS
        ${DLITE_ROOT}/${DLITE_RUNTIME_DIR}
        ${dlite-tools_BINARY_DIR}
        ${dlite_PATH}
      )
    list(APPEND codegen_dependencies ${DLITE_ENV})
  endif()

  add_custom_command(
    OUTPUT ${output}
    COMMAND
      ${DLITE_ENV}
        ${env_options}
        --
        ${DLITE_CODEGEN}
          --output=${output}
          ${template_option}
          ${url}
          ${codegen_extra_options}
    DEPENDS ${codegen_dependencies}
    COMMENT "Generate ${output}"
  )

endmacro()
