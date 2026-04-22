/* Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT */

/**
 * @name Unannotated external declaration under mldsa/
 * @description Externally-linked declarations under mldsa/ must carry a
 *              visibility annotation macro so that single-CU builds hide
 *              internal symbols correctly.  Functions need
 *              MLD_INTERNAL_API, MLD_EXTERNAL_API, or MLD_API_QUALIFIER;
 *              file-scope variables need MLD_INTERNAL_DATA_DEFINITION
 *              (for definitions) or MLD_INTERNAL_DATA_DECLARATION
 *              (for declarations).
 * @kind problem
 * @problem.severity error
 * @id mldsa/unannotated-external-declaration
 */

import cpp

/* A declaration is "in mldsa/" if its location's file path contains /mldsa/. */
predicate inMldsaTree(Declaration d) {
  d.getFile().getAbsolutePath().matches("%/mldsa/%")
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

/* True when e carries an annotation appropriate to its kind/role. */
predicate hasCorrectVisibilityMacro(DeclarationEntry e) {
  exists(string m | m = visibilityMacro(e) |
    e.getDeclaration() instanceof Function and
    (m = "MLD_INTERNAL_API" or m = "MLD_EXTERNAL_API" or m = "MLD_API_QUALIFIER")
    or
    e.getDeclaration() instanceof GlobalOrNamespaceVariable and
    e.isDefinition() and m = "MLD_INTERNAL_DATA_DEFINITION"
    or
    e.getDeclaration() instanceof GlobalOrNamespaceVariable and
    not e.isDefinition() and m = "MLD_INTERNAL_DATA_DECLARATION"
  )
}

string expectedVisibilityMacro(DeclarationEntry e) {
  e.getDeclaration() instanceof Function and
  result = "MLD_INTERNAL_API, MLD_EXTERNAL_API, or MLD_API_QUALIFIER"
  or
  e.getDeclaration() instanceof GlobalOrNamespaceVariable and
  e.isDefinition() and
  result = "MLD_INTERNAL_DATA_DEFINITION"
  or
  e.getDeclaration() instanceof GlobalOrNamespaceVariable and
  not e.isDefinition() and
  result = "MLD_INTERNAL_DATA_DECLARATION"
}

from DeclarationEntry e, Declaration d
where
  d = e.getDeclaration() and
  inMldsaTree(d) and
  not d.getName().matches("%empty_cu_%") and
  not d.getName().matches("%_asm") and
  (d instanceof Function or d instanceof GlobalOrNamespaceVariable) and
  not e.hasSpecifier("static") and
  not hasCorrectVisibilityMacro(e)
select e,
  "'" + d.getName() + "' has external linkage and must carry " +
  expectedVisibilityMacro(e) + "."
