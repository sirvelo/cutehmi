#ifndef H_MODULES_CUTEHMI_u_1_INCLUDE_CUTEHMI_EXCEPTION_HPP
#define H_MODULES_CUTEHMI_u_1_INCLUDE_CUTEHMI_EXCEPTION_HPP

#include "internal/common.hpp"

#include <QCoreApplication>
#include <QException>

namespace cutehmi {

/**
 * %Exception.
 */
class CUTEHMI_API Exception:
	public QException
{
	Q_DECLARE_TR_FUNCTIONS(cutehmi::Exception) // This macro ends with "private:" specifier :o !!!

	public:
		Exception(const QString & what);

		void raise() const noexcept(false) override;

		Exception * clone() const override;

		const char * what() const noexcept override;

	private:
		QByteArray m_whatArr;
};

}

#endif

//(c)MP: Copyright © 2018, Michal Policht. All rights reserved.
//(c)MP: This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
