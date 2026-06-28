/*
 * Copyright (c) The mldsa-native project authors
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
 */
#ifndef MLD_CONTEXT_H
#define MLD_CONTEXT_H

/* This header is included by common.h once the configuration has been pulled
 * in; it is not meant to be included directly. */

/*
 * If the integration wants to provide a context parameter for use in
 * platform-specific hooks, then it should define this parameter.
 *
 * The MLD_CONTEXT_PARAMETERS_n macros are intended to be used with macros
 * defining the function names and expand to either pass or discard the context
 * argument as required by the current build.  If there is no context parameter
 * requested then these are removed from the prototypes and from all calls.
 */
#ifdef MLD_CONFIG_CONTEXT_PARAMETER
#define MLD_CONTEXT_PARAMETERS_0(context) (context)
#define MLD_CONTEXT_PARAMETERS_1(arg0, context) (arg0, context)
#define MLD_CONTEXT_PARAMETERS_2(arg0, arg1, context) (arg0, arg1, context)
#define MLD_CONTEXT_PARAMETERS_3(arg0, arg1, arg2, context) \
  (arg0, arg1, arg2, context)
#define MLD_CONTEXT_PARAMETERS_4(arg0, arg1, arg2, arg3, context) \
  (arg0, arg1, arg2, arg3, context)
#define MLD_CONTEXT_PARAMETERS_5(arg0, arg1, arg2, arg3, arg4, context) \
  (arg0, arg1, arg2, arg3, arg4, context)
#define MLD_CONTEXT_PARAMETERS_6(arg0, arg1, arg2, arg3, arg4, arg5, context) \
  (arg0, arg1, arg2, arg3, arg4, arg5, context)
#define MLD_CONTEXT_PARAMETERS_7(arg0, arg1, arg2, arg3, arg4, arg5, arg6, \
                                 context)                                  \
  (arg0, arg1, arg2, arg3, arg4, arg5, arg6, context)
#define MLD_CONTEXT_PARAMETERS_8(arg0, arg1, arg2, arg3, arg4, arg5, arg6, \
                                 arg7, context)                            \
  (arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, context)
#define MLD_CONTEXT_PARAMETERS_9(arg0, arg1, arg2, arg3, arg4, arg5, arg6, \
                                 arg7, arg8, context)                      \
  (arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, context)
#else /* MLD_CONFIG_CONTEXT_PARAMETER */
#define MLD_CONTEXT_PARAMETERS_0(context) ()
#define MLD_CONTEXT_PARAMETERS_1(arg0, context) (arg0)
#define MLD_CONTEXT_PARAMETERS_2(arg0, arg1, context) (arg0, arg1)
#define MLD_CONTEXT_PARAMETERS_3(arg0, arg1, arg2, context) (arg0, arg1, arg2)
#define MLD_CONTEXT_PARAMETERS_4(arg0, arg1, arg2, arg3, context) \
  (arg0, arg1, arg2, arg3)
#define MLD_CONTEXT_PARAMETERS_5(arg0, arg1, arg2, arg3, arg4, context) \
  (arg0, arg1, arg2, arg3, arg4)
#define MLD_CONTEXT_PARAMETERS_6(arg0, arg1, arg2, arg3, arg4, arg5, context) \
  (arg0, arg1, arg2, arg3, arg4, arg5)
#define MLD_CONTEXT_PARAMETERS_7(arg0, arg1, arg2, arg3, arg4, arg5, arg6, \
                                 context)                                  \
  (arg0, arg1, arg2, arg3, arg4, arg5, arg6)
#define MLD_CONTEXT_PARAMETERS_8(arg0, arg1, arg2, arg3, arg4, arg5, arg6, \
                                 arg7, context)                            \
  (arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#define MLD_CONTEXT_PARAMETERS_9(arg0, arg1, arg2, arg3, arg4, arg5, arg6, \
                                 arg7, arg8, context)                      \
  (arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
#endif /* !MLD_CONFIG_CONTEXT_PARAMETER */

#if defined(MLD_CONFIG_CONTEXT_PARAMETER_TYPE) != \
    defined(MLD_CONFIG_CONTEXT_PARAMETER)
#error MLD_CONFIG_CONTEXT_PARAMETER_TYPE must be defined if and only if MLD_CONFIG_CONTEXT_PARAMETER is defined
#endif

#endif /* !MLD_CONTEXT_H */
