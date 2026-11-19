// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Project Vice: the product's own name wherever the app shows one.

#ifndef VICE_BRAND_H
#define VICE_BRAND_H

#define VICE_APP_NAME "Project Vice"
#define VICE_DESKTOP_FILE "project-vice"

/**
 * Installs a translator that puts the product's name in place of upstream's
 * in every translated string (tr() and qsTr()), so upstream's own texts need
 * no edits. Call once, after the application object exists.
 */
void viceInstallBranding();

#endif // VICE_BRAND_H
