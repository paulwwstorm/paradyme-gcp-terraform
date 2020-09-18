#!/usr/bin/env python

import os
import sys
import json

from time import sleep
from kafka import KafkaConsumer, KafkaProducer, TopicPartition
from util.http_status_server import HttpHealthServer
from util.task_args import get_kafka_binder_brokers, get_input_channel, get_output_channel

import logging

logger = logging.getLogger('kafka')
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.INFO)

logger.warning("Test warning mesage logger 12345 helllo")

consumer = KafkaConsumer(bootstrap_servers=[get_kafka_binder_brokers()],api_version=(0,9),group_id=None,auto_offset_reset='latest')
producer = KafkaProducer(bootstrap_servers=[get_kafka_binder_brokers()],api_version=(0,9))

tp = TopicPartition("two-forty.input", 0)
consumer.assign([tp])
consumer.seek_to_end()

HttpHealthServer.run_thread()

counter = 0

while True:
    for message in consumer:
        producer.send("new_message", message)

