/*
 * revert.c:  wrapper around wc revert functionality.
 *
 * ====================================================================
 *    Licensed to the Apache Software Foundation (ASF) under one
 *    or more contributor license agreements.  See the NOTICE file
 *    distributed with this work for additional information
 *    regarding copyright ownership.  The ASF licenses this file
 *    to you under the Apache License, Version 2.0 (the
 *    "License"); you may not use this file except in compliance
 *    with the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing,
 *    software distributed under the License is distributed on an
 *    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *    KIND, either express or implied.  See the License for the
 *    specific language governing permissions and limitations
 *    under the License.
 * ====================================================================
 */

/* ==================================================================== */



/*** Includes. ***/

#include "svn_wc.h"
#include "svn_client.h"
#include "svn_dirent_uri.h"
#include "svn_pools.h"
#include "svn_error.h"
#include "svn_time.h"
#include "svn_config.h"
#include "client.h"
#include "private/svn_wc_private.h"



/*** Code. ***/

/* Attempt to revert PATH.

   If DEPTH is svn_depth_empty, revert just the properties on the
   directory; else if svn_depth_files, revert the properties and any
   files immediately under the directory; else if
   svn_depth_immediates, revert all of the preceding plus properties
   on immediate subdirectories; else if svn_depth_infinity, revert
   path and everything under it fully recursively.

   CHANGELISTS is an array of const char * changelist names, used as a
   restrictive filter on items reverted; that is, don't revert any
   item unless it's a member of one of those changelists.  If
   CHANGELISTS is empty (or altogether NULL), no changelist filtering occurs.

   Consult CTX to determine whether or not to revert timestamp to the
   time of last commit ('use-commit-times = yes').  Use POOL for
   temporary allocation.

   If PATH is unversioned, return SVN_ERR_UNVERSIONED_RESOURCE. */
static svn_error_t *
revert(const char *path,
       svn_depth_t depth,
       svn_boolean_t use_commit_times,
       const apr_array_header_t *changelists,
       svn_client_ctx_t *ctx,
       apr_pool_t *pool)
{
  svn_wc_adm_access_t *adm_access, *target_access;
  const char *target, *local_abspath;
  svn_error_t *err;
  int adm_lock_level = SVN_WC__LEVELS_TO_LOCK_FROM_DEPTH(depth);

  SVN_ERR(svn_wc__adm_open_anchor_in_context(
                                 &adm_access, &target_access, &target,
                                 ctx->wc_ctx, path, TRUE, adm_lock_level,
                                 ctx->cancel_func, ctx->cancel_baton,
                                 pool));

  SVN_ERR(svn_dirent_get_absolute(&local_abspath, path, pool));

  err = svn_wc_revert4(ctx->wc_ctx,
                       local_abspath,
                       depth,
                       use_commit_times,
                       changelists,
                       ctx->cancel_func, ctx->cancel_baton,
                       ctx->notify_func2, ctx->notify_baton2,
                       pool);

  if (err)
    {
      /* If target isn't versioned, just send a 'skip'
         notification and move on. */
      if (err->apr_err == SVN_ERR_ENTRY_NOT_FOUND
          || err->apr_err == SVN_ERR_UNVERSIONED_RESOURCE)
        {
          if (ctx->notify_func2)
            (*ctx->notify_func2)
              (ctx->notify_baton2,
               svn_wc_create_notify(path, svn_wc_notify_skip, pool),
               pool);
          svn_error_clear(err);
        }
      else
        return svn_error_return(err);
    }

  return svn_wc_adm_close2(adm_access, pool);
}


svn_error_t *
svn_client_revert2(const apr_array_header_t *paths,
                   svn_depth_t depth,
                   const apr_array_header_t *changelists,
                   svn_client_ctx_t *ctx,
                   apr_pool_t *pool)
{
  apr_pool_t *subpool;
  svn_error_t *err = SVN_NO_ERROR;
  int i;
  svn_config_t *cfg;
  svn_boolean_t use_commit_times;

  cfg = ctx->config ? apr_hash_get(ctx->config, SVN_CONFIG_CATEGORY_CONFIG,
                                   APR_HASH_KEY_STRING) : NULL;

  SVN_ERR(svn_config_get_bool(cfg, &use_commit_times,
                              SVN_CONFIG_SECTION_MISCELLANY,
                              SVN_CONFIG_OPTION_USE_COMMIT_TIMES,
                              FALSE));

  subpool = svn_pool_create(pool);

  for (i = 0; i < paths->nelts; i++)
    {
      const char *path = APR_ARRAY_IDX(paths, i, const char *);

      svn_pool_clear(subpool);

      /* See if we've been asked to cancel this operation. */
      if ((ctx->cancel_func)
          && ((err = ctx->cancel_func(ctx->cancel_baton))))
        goto errorful;

      err = revert(path, depth, use_commit_times, changelists, ctx, subpool);
      if (err)
        goto errorful;
    }

 errorful:

  if (!use_commit_times)
    {
      /* Sleep to ensure timestamp integrity. */
      const char* sleep_path = NULL;

      /* Only specify a path if we are certain all paths are on the
         same filesystem */
      if (paths->nelts == 1)
        sleep_path = APR_ARRAY_IDX(paths, 0, const char *);

      svn_io_sleep_for_timestamps(sleep_path, subpool);
    }

  svn_pool_destroy(subpool);

  return svn_error_return(err);
}
