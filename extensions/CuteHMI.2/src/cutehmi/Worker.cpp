#include "../../include/cutehmi/Worker.hpp"

#include <QCoreApplication>

namespace cutehmi {

Worker::Worker(std::function<void()> task):
	m(new Members(task))
{
}

Worker::Worker(QThread & thread):
	Worker()
{
	employ(thread, false);
}

Worker::~Worker()
{
	// This acts as a failproof synchronization mechanism that prevents deletion before object finishes processing WorkEvent.
	m->workMutex.lock();
	m->workMutex.unlock();	// Mutex should be unlocked before it gets deleted.
}

void Worker::setTask(std::function<void()> task)
{
	m->task = task;
}

void Worker::job()
{
	if (m->task)
		m->task();
}

void Worker::wait() const
{
	m->stateMutex.lock();
	if (m->state == State::WORKING)
		// wait() uses internal mechanisms to prevent wakeAll() from waking up threads after m->stateMutex is locked.
		m->waitCondition.wait(& m->stateMutex);
	m->stateMutex.unlock();
}

bool Worker::isReady() const
{
	QMutexLocker locker(& m->stateMutex);
	return m->state == State::READY;
}

bool Worker::isWorking() const
{
	QMutexLocker locker(& m->stateMutex);
	return m->state == State::WORKING;
}

void Worker::employ(QThread & thread, bool start)
{
	moveToThread(& thread);
	m->state = State::EMPLOYED;
	if (start)
		work();
}

void Worker::work()
{
	m->workMutex.lock();
	m->stateMutex.lock();
	m->state = State::WORKING;
	m->stateMutex.unlock();
	QCoreApplication::postEvent(this, new WorkEvent);
}

bool Worker::event(QEvent * event)
{
	if (event->type() == WorkEvent::RegisteredType()) {
		job();
		m->stateMutex.lock();
		m->state = State::READY;
		emit ready();
		m->waitCondition.wakeAll();
		m->stateMutex.unlock();

//<principle id="cutehmi::Worker-member_access_forbidden">
// After unlocking m->workMutex object may be deleted from its former thread.
// From now on members of Worker object must not be accessed from within itself or undefined behaviour will occur.
		m->workMutex.unlock();
		return true;
//</principle>
	}

	return Parent::event(event);
}

QEvent::Type Worker::WorkEvent::RegisteredType() noexcept
{
	static const QEvent::Type type = static_cast<QEvent::Type>(QEvent::registerEventType());
	return type;
}

Worker::WorkEvent::WorkEvent():
	QEvent(RegisteredType())
{
}

}

//(c)MP: Copyright © 2019, Michal Policht <michpolicht@gmail.com>. All rights reserved.
//(c)MP: This file is a part of CuteHMI.
//(c)MP: CuteHMI is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//(c)MP: CuteHMI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
//(c)MP: You should have received a copy of the GNU Lesser General Public License along with CuteHMI.  If not, see <https://www.gnu.org/licenses/>.