/* Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT */

/**
 * @name All declarations under mldsa/
 * @description Enumerates every function and (file-scope) variable declaration
 *              located under the mldsa/ source tree, together with its linkage.
 * @kind table
 * @id mldsa/all-declarations
 */

import cpp

/* A declaration is "in mldsa/" if its location's file path contains /mldsa/. */
predicate inMldsaTree(Declaration d) {
  exists(string path | path = d.getFile().getAbsolutePath() |
    path.matches("%/mldsa/%")
  )
}

predicate isVisibilityMacro(string name) {
  name = "MLD_INTERNAL_API" or
  name = "MLD_EXTERNAL_API" or
  name = "MLD_INTERNAL_DATA_DECLARATION" or
  name = "MLD_INTERNAL_DATA_DEFINITION" or
  name = "MLD_API_QUALIFIER"
}

/* Visibility macro invocation sitting on (or up to 4 lines above) this
 * declaration entry, with no intervening declaration entry in between. */
string visibilityMacro(DeclarationEntry e) {
  result =
    min(MacroInvocation mi, string name, int line |
      name = mi.getMacroName() and
      isVisibilityMacro(name) and
      mi.getFile() = e.getFile() and
      line = mi.getLocation().getEndLine() and
      line <= e.getLocation().getStartLine() and
      line >= e.getLocation().getStartLine() - 4 and
      /* No other declaration entry sits between the macro and e. */
      not exists(DeclarationEntry other |
        other != e and
        other.getFile() = e.getFile() and
        other.getLocation().getStartLine() > line and
        other.getLocation().getStartLine() < e.getLocation().getStartLine()
      )
    |
      name order by line desc
    )
}

/* Functions: one row per declaration entry (prototype in a .h, definition in
 * a .c) so we can check *each* site individually. */
from
  DeclarationEntry e, Declaration d, string kind, string linkage,
  string annotation, string def_or_decl
where
  d = e.getDeclaration() and
  inMldsaTree(d) and
  not d.getName().matches("%empty_cu_%") and
  not d.getName().matches("%_asm") and
  (
    d instanceof Function and kind = "function"
    or
    d instanceof GlobalOrNamespaceVariable and kind = "variable"
  ) and
  (
    if e.hasSpecifier("static")
    then linkage = "static"
    else linkage = "extern"
  ) and
  (
    annotation = visibilityMacro(e)
    or
    not exists(visibilityMacro(e)) and annotation = "(none)"
  ) and
  (
    if e.isDefinition()
    then def_or_decl = "definition"
    else def_or_decl = "declaration"
  )
select
  e.getFile().getRelativePath() + ":" + e.getLocation().getStartLine() as location,
  kind,
  def_or_decl,
  linkage,
  annotation,
  d.getName() as name
