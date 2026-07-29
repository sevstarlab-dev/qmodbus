#ifndef SERIALSETTINGSWIDGET_H
#define SERIALSETTINGSWIDGET_H

#include <QWidget>
#include "imodbus.h"
#include "modbus.h"

class QextSerialEnumerator;
class QextPortInfo;
class QTimer;

namespace Ui {
class SerialSettingsWidget;
}


class SerialSettingsWidget : public QWidget, public IModbus
{
	Q_OBJECT

public:
	SerialSettingsWidget(QWidget *parent = 0);
	virtual ~SerialSettingsWidget();

	virtual modbus_t*  modbus() { return m_serialModbus; }

	virtual int setupModbusPort();

protected:
	virtual void changeModbusInterface(const QString &port, char parity) = 0;
	void releaseSerialModbus();
	void enableGuiItems(bool checked);

    Ui::SerialSettingsWidget *ui;
    modbus_t *                m_serialModbus;

signals:
	void serialPortActive(bool active);
	void connectionError(const QString &msg);

public slots:
	void changeSerialPort(int);

private slots:
	void on_checkBox_clicked(bool checked);
	void onSerialPortsChanged();
	void refreshSerialPorts();

private:
	bool isSerialActive() const;
	QString portDisplayName(const QextPortInfo &port) const;
	QString portDeviceName(const QextPortInfo &port) const;

	QextSerialEnumerator *m_enumerator;
	QTimer *m_refreshPortsTimer;
};

#endif // SERIALSETTINGSWIDGET_H
