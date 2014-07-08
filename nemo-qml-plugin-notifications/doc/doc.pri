QDOC = qdoc
QDOCCONF = config/nemo-qml-plugin-notifications.qdocconf

docs.commands = ($$QDOC $$PWD/$$QDOCCONF)

QMAKE_EXTRA_TARGETS += docs

