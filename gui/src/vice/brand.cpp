// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "vice/brand.h"

#include <QCoreApplication>
#include <QRegularExpression>
#include <QTranslator>

namespace {

class BrandTranslator : public QTranslator
{
	public:
		using QTranslator::QTranslator;

		bool isEmpty() const override { return false; }

		QString translate(const char *, const char *sourceText, const char *, int) const override
		{
			// An empty answer means "not mine": Qt then uses the source text or the next translator
			const QString text = QString::fromUtf8(sourceText);
			if(!text.contains(QLatin1String("chiaki"), Qt::CaseInsensitive))
				return QString();
			static const QRegularExpression upstream_name(QStringLiteral("chiaki(-ng|4deck)?"),
					QRegularExpression::CaseInsensitiveOption);
			QString out = text;
			out.replace(upstream_name, QStringLiteral(VICE_APP_NAME));
			return out;
		}
};

} // namespace

void viceInstallBranding()
{
	QCoreApplication::installTranslator(new BrandTranslator(QCoreApplication::instance()));
}
