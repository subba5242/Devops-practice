/*
 * svn_wc.i :  SWIG interface file for svn_wc.h
 *
 * ====================================================================
 * Copyright (c) 2000-2003 CollabNet.  All rights reserved.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution.  The terms
 * are also available at http://subversion.tigris.org/license-1.html.
 * If newer versions of this license are posted there, you may use a
 * newer version instead, at your option.
 *
 * This software consists of voluntary contributions made by many
 * individuals.  For exact contribution history, see the revision
 * history and logs, available at http://subversion.tigris.org/.
 * ====================================================================
 */

#if defined(SWIGPERL)
%module "SVN::_Wc"
#elif defined(SWIGRUBY)
%module "svn::ext::wc"
#else
%module wc
#endif

%include typemaps.i

%include svn_global.swg
%import apr.swg
%import core.i
%import svn_types.swg
%import svn_string.swg
%import svn_delta.i
%import svn_ra.i

/* -----------------------------------------------------------------------
   ### these functions require a pool, which we don't have immediately
   ### handy. just eliminate these funcs for now.
*/
%ignore svn_wc_set_auth_file;

/* ### ignore this structure because the accessors will need a pool */
%ignore svn_wc_keywords_t;

/* -----------------------------------------------------------------------
   %apply-ing of typemaps defined elsewhere
*/

%apply SWIGTYPE **OUTPARAM {
    svn_wc_entry_t **,
    svn_wc_adm_access_t **,
    svn_wc_status_t **
};

/* svn_wc_check_wc(wc_format) */
%apply int *OUTPUT { int * };

/*
   svn_wc_prop_list()
   svn_wc_get_prop_diffs()
*/
%apply apr_hash_t **PROPHASH {
  apr_hash_t **props,
  apr_hash_t **original_props
};

/* svn_wc_get_prop_diffs() */
%apply apr_array_header_t **OUTPUT_OF_PROP {
  apr_array_header_t **propchanges
};

%apply apr_hash_t *PROPHASH {
  apr_hash_t *baseprops
};


/* -----------------------------------------------------------------------
   apr_hash_t ** <const char *, const svn_wc_entry_t *>
   svn_wc_entries_read()
*/

%typemap(python, in, numinputs=0) apr_hash_t **entries = apr_hash_t **OUTPUT;
%typemap(python, argout, fragment="t_output_helper") apr_hash_t **entries {
    $result = t_output_helper(
        $result,
        svn_swig_py_convert_hash(*$1, $descriptor(svn_wc_entry_t *),
          _global_svn_swig_py_pool));
}

%typemap(ruby, in, numinputs=0) apr_hash_t **entries = apr_hash_t **OUTPUT;
%typemap(ruby, argout, fragment="output_helper") apr_hash_t **entries
{
  $result = output_helper($result,
                          svn_swig_rb_apr_hash_to_hash_swig_type
                            (*$1, "svn_wc_entry_t *"));
}

/* -----------------------------------------------------------------------
   apr_array_header_t **externals_p
   svn_wc_parse_externals_description2()
*/

%typemap(ruby, in, numinputs=0)
     apr_array_header_t **externals_p (apr_array_header_t *temp)
{
  $1 = &temp;
}
%typemap(ruby, argout, fragment="output_helper")
     apr_array_header_t **externals_p
{
  $result = output_helper($result,
                          svn_swig_rb_apr_array_to_array_external_item(*$1));
}

/* -----------------------------------------------------------------------
   apr_array_header_t *wcprop_changes
   svn_wc_process_committed2()
*/

%typemap(ruby, in) apr_array_header_t *wcprop_changes
{
  VALUE rb_pool;
  apr_pool_t *pool;

  svn_swig_rb_get_pool(argc, argv, self, &rb_pool, &pool);
        
  $1 = svn_swig_rb_array_to_apr_array_prop($input, pool);
}

/* -----------------------------------------------------------------------
   apr_array_header_t *propchanges
   svn_wc_merge_props()
*/
%typemap(ruby, in) apr_array_header_t *propchanges
{
  VALUE rb_pool;
  apr_pool_t *pool;

  svn_swig_rb_get_pool(argc, argv, self, &rb_pool, &pool);
        
  $1 = svn_swig_rb_array_to_apr_array_prop($input, pool);
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_notify_func_t
   svn_client_ctx_t
   svn_wc many
*/

%typemap(python,in) (svn_wc_notify_func_t notify_func, void *notify_baton) {
  $1 = svn_swig_py_notify_func;
  $2 = $input; /* our function is the baton. */
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_notify_func2_t
   svn_client_ctx_t
   svn_wc many
*/

%typemap(ruby, in) (svn_wc_notify_func2_t notify_func2, void *notify_baton2)
{
  $1 = svn_swig_rb_notify_func2;
  $2 = (void *)$input;
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_entry_callbacks_t
   svn_wc_walk_entries2()
*/

%typemap(ruby, in) (const svn_wc_entry_callbacks_t *walk_callbacks,
                    void *walk_baton)
{
  $1 = svn_swig_rb_wc_entry_callbacks();
  $2 = (void *)$input;
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_status_func_t
   svn_client_status()
   svn_wc_get_status_editor()
*/

%typemap(python,in) (svn_wc_status_func_t status_func, void *status_baton) {
  $1 = svn_swig_py_status_func;
  $2 = $input; /* our function is the baton. */
}

%typemap(perl5,in) (svn_wc_status_func_t status_func, void *status_baton) {
  $1 = svn_swig_pl_status_func;
  $2 = $input; /* our function is the baton. */
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_status_func2_t
   svn_client_status2()
   svn_wc_get_status_editor2()
*/

%typemap(ruby, in) (svn_wc_status_func2_t status_func,
                    void *status_baton)
{
  $1 = svn_swig_rb_wc_status_func;
  $2 = (void *)$input;
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_callbacks2_t
   svn_wc_get_diff_editor3()
*/

%typemap(ruby, in) (const svn_wc_diff_callbacks2_t *callbacks,
                    void *callback_baton)
{
  $1 = svn_swig_rb_wc_diff_callbacks2();
  $2 = (void *)$input;
}

/* -----------------------------------------------------------------------
   Callback: svn_wc_relocation_validator_t
   svn_wc_relocate()
*/

%typemap(ruby, in) (svn_wc_relocation_validator_t validator,
                    void *validator_baton)
{
  $1 = svn_swig_rb_wc_relocation_validator;
  $2 = (void *)$input;
}

/* ----------------------------------------------------------------------- */

%{
#ifdef SWIGPYTHON
#include "swigutil_py.h"
#endif

#ifdef SWIGPERL
#include "swigutil_pl.h"
#endif

#ifdef SWIGRUBY
#include "swigutil_rb.h"
#endif
%}

%include svn_wc_h.swg
