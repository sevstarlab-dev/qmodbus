#include <QSettings>
#include <QTimer>
#include "qextserialenumerator.h"
#include "serialsettingswidget.h"
#include "ui_serialsettingswidget.h"

SerialSettingsWidget::SerialSettingsWidget(QWidget *parent) :
	QWidget(parent),
	ui(new Ui::SerialSettingsWidget),
	m_serialModbus( NULL ),
	m_enumerator( new QextSerialEnumerator() ),
	m_refreshPortsTimer( new QTimer(this) )
{
	ui->setupUi(this);

	m_refreshPortsTimer->setSingleShot(true);
	m_refreshPortsTimer->setInterval(100);
	connect(m_refreshPortsTimer, SIGNAL(timeout()), this, SLOT(refreshSerialPorts()));

	connect(m_enumerator, SIGNAL(deviceDiscovered(QextPortInfo)),
			this, SLOT(onSerialPortsChanged()));
	connect(m_enumerator, SIGNAL(deviceRemoved(QextPortInfo)),
			this, SLOT(onSerialPortsChanged()));
	m_enumerator->setUpNotifications();

	connect( ui->serialPort, SIGNAL( currentIndexChanged( int ) ),
			this, SLOT( changeSerialPort( int ) ) );
	connect( ui->baud, SIGNAL( currentIndexChanged( int ) ),
			this, SLOT( changeSerialPort( int ) ) );
	connect( ui->dataBits, SIGNAL( currentIndexChanged( int ) ),
			this, SLOT( changeSerialPort( int ) ) );
	connect( ui->stopBits, SIGNAL( currentIndexChanged( int ) ),
			this, SLOT( changeSerialPort( int ) ) );
	connect( ui->parity, SIGNAL( currentIndexChanged( int ) ),
			this, SLOT( changeSerialPort( int ) ) );

	refreshSerialPorts();
	enableGuiItems(false);
}

SerialSettingsWidget::~SerialSettingsWidget()
{
	delete m_enumerator;
	delete ui;
}

bool SerialSettingsWidget::isSerialActive() const
{
	return ui->checkBox->isChecked();
}

QString SerialSettingsWidget::portDisplayName(const QextPortInfo &port) const
{
#ifdef Q_OS_WIN
	return port.friendName;
#else
	return port.physName;
#endif
}

QString SerialSettingsWidget::portDeviceName(const QextPortInfo &port) const
{
#ifdef Q_OS_WIN
	return port.portName;
#else
	return port.physName;
#endif
}

void SerialSettingsWidget::onSerialPortsChanged()
{
	m_refreshPortsTimer->start();
}

void SerialSettingsWidget::refreshSerialPorts()
{
	const QString previousPort = ui->serialPort->currentData().toString();
	const QString savedInterface = QSettings().value("serialinterface").toString();
	const bool wasBlocked = ui->serialPort->blockSignals(true);

	ui->serialPort->clear();

	QList<QextPortInfo> ports = QextSerialEnumerator::getPorts();
	int selectedIndex = -1;
	int savedIndex = -1;
	int i = 0;
	foreach( const QextPortInfo &port, ports )
	{
		const QString displayName = portDisplayName(port);
		const QString deviceName = portDeviceName(port);
		ui->serialPort->addItem(displayName, deviceName);

		if( !previousPort.isEmpty() && deviceName == previousPort )
			selectedIndex = i;
		if( displayName == savedInterface )
			savedIndex = i;
		++i;
	}

	int portIndex = 0;
	if( selectedIndex >= 0 )
		portIndex = selectedIndex;
	else if( savedIndex >= 0 )
		portIndex = savedIndex;

	ui->serialPort->setCurrentIndex(portIndex);
	ui->serialPort->blockSignals(wasBlocked);

	if( isSerialActive() )
	{
		const QString currentPort = ui->serialPort->currentData().toString();
		if( previousPort.isEmpty() || currentPort != previousPort || ports.isEmpty() )
			changeSerialPort(portIndex);
	}
}

int SerialSettingsWidget::setupModbusPort()
{
	QSettings s;

	refreshSerialPorts();

	ui->baud->blockSignals(true);
	ui->parity->blockSignals(true);
	ui->stopBits->blockSignals(true);
	ui->dataBits->blockSignals(true);

	ui->baud->setCurrentIndex( ui->baud->findText( s.value( "serialbaudrate" ).toString() ) );
	ui->parity->setCurrentIndex( ui->parity->findText( s.value( "serialparity" ).toString() ) );
	ui->stopBits->setCurrentIndex( ui->stopBits->findText( s.value( "serialstopbits" ).toString() ) );
	ui->dataBits->setCurrentIndex( ui->dataBits->findText( s.value( "serialdatabits" ).toString() ) );

	ui->baud->blockSignals(false);
	ui->parity->blockSignals(false);
	ui->stopBits->blockSignals(false);
	ui->dataBits->blockSignals(false);

	const int portIndex = ui->serialPort->currentIndex();
	changeSerialPort( portIndex );
	return portIndex;
}

void SerialSettingsWidget::releaseSerialModbus()
{
	if( m_serialModbus )
	{
		modbus_close( m_serialModbus );
		modbus_free( m_serialModbus );
		m_serialModbus = NULL;
	}
}

void SerialSettingsWidget::changeSerialPort( int )
{
	if( !isSerialActive() )
		return;

	const QString deviceName = ui->serialPort->currentData().toString();
	if( deviceName.isEmpty() || ui->serialPort->count() == 0 )
	{
		releaseSerialModbus();
		emit serialPortActive(false);
		emit connectionError( tr( "No serial port found" ) );
		return;
	}

	QSettings settings;
	settings.setValue( "serialinterface", ui->serialPort->currentText() );
	settings.setValue( "serialbaudrate", ui->baud->currentText() );
	settings.setValue( "serialparity", ui->parity->currentText() );
	settings.setValue( "serialdatabits", ui->dataBits->currentText() );
	settings.setValue( "serialstopbits", ui->stopBits->currentText() );

#ifdef Q_OS_WIN32
	QString port = deviceName;

	// is it a serial port in the range COM1 .. COM9?
	if ( port.startsWith( "COM" ) )
	{
		// use windows communication device name "\\.\COMn"
		port = "\\\\.\\" + port;
	}
#else
	const QString port = deviceName;
#endif

	char parity;
	switch( ui->parity->currentIndex() )
	{
		case 1: parity = 'O'; break;
		case 2: parity = 'E'; break;
		default:
		case 0: parity = 'N'; break;
	}

	changeModbusInterface(port, parity);

	emit serialPortActive(m_serialModbus != NULL);
}


void SerialSettingsWidget::enableGuiItems(bool checked)
{
	ui->serialPort->setEnabled(checked);
	ui->baud->setEnabled(checked);
	ui->dataBits->setEnabled(checked);
	ui->stopBits->setEnabled(checked);
	ui->parity->setEnabled(checked);
}

void SerialSettingsWidget::on_checkBox_clicked(bool checked)
{
	if (checked) {
		setupModbusPort();
	}
	else {
		releaseSerialModbus();
	}
	enableGuiItems(checked);
	emit serialPortActive(checked && m_serialModbus != NULL);
}
