#!/bin/bash

TOMLDECODER_FORMATTING=1 swift package -c release plugin --allow-writing-to-package-directory swiftformat $@
