* © Copyright IBM Corporation 2017, 2019
*
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.

* Developer queues
DEFINE QLOCAL('DEV.QUEUE.1') REPLACE
DEFINE QLOCAL('DEV.QUEUE.2') REPLACE
DEFINE QLOCAL('DEV.QUEUE.3') REPLACE
DEFINE QLOCAL('DEV.DEAD.LETTER.QUEUE') REPLACE

* Use a different dead letter queue, for undeliverable messages
ALTER QMGR DEADQ('DEV.DEAD.LETTER.QUEUE')

* Developer topics
DEFINE TOPIC('DEV.BASE.TOPIC') TOPICSTR('dev/') REPLACE

* Developer connection authentication
* DEFINE AUTHINFO('DEV.AUTHINFO') AUTHTYPE(IDPWOS) CHCKCLNT(REQDADM) CHCKLOCL(OPTIONAL) ADOPTCTX(YES) REPLACE
* ALTER QMGR CONNAUTH('DEV.AUTHINFO')
* REFRESH SECURITY(*) TYPE(CONNAUTH)


* Developer channels (Application + Admin)
* Developer channels (Application + Admin)
DEFINE CHANNEL('DEV.ADMIN.SVRCONN') CHLTYPE(SVRCONN) REPLACE
DEFINE CHANNEL('DEV.APP.SVRCONN') CHLTYPE(SVRCONN) MCAUSER('app') REPLACE

* Developer channel authentication rules
* SET CHLAUTH('*') TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(NOACCESS) DESCR('Back-stop rule - Blocks everyone') ACTION(REPLACE)
SET CHLAUTH('*') TYPE(BLOCKUSER) USERLIST('nobody') DESCR('Allow privileged users on all channels')

SET CHLAUTH('DEV.APP.SVRCONN') TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(CHANNEL) CHCKCLNT({{ .ChckClnt }}) DESCR('Allows connection via APP channel') ACTION(REPLACE)
SET CHLAUTH('DEV.ADMIN.SVRCONN') TYPE(BLOCKUSER) USERLIST('nobody') DESCR('Allows admins on ADMIN channel') ACTION(REPLACE)
SET CHLAUTH('DEV.ADMIN.SVRCONN') TYPE(USERMAP) CLNTUSER('admin') USERSRC(CHANNEL) DESCR('Allows admin user to connect via ADMIN channel') ACTION(REPLACE)
SET CHLAUTH('DEV.ADMIN.SVRCONN') TYPE(USERMAP) CLNTUSER('admin') USERSRC(MAP) MCAUSER ('mqm') DESCR ('Allow admin as MQ-admin') ACTION(REPLACE)

* Developer authority records
SET AUTHREC PRINCIPAL('app') OBJTYPE(QMGR) AUTHADD(CONNECT,INQ)
SET AUTHREC PROFILE('DEV.**') PRINCIPAL('app') OBJTYPE(QUEUE) AUTHADD(BROWSE,GET,INQ,PUT)
SET AUTHREC PROFILE('DEV.**') PRINCIPAL('app') OBJTYPE(TOPIC) AUTHADD(PUB,SUB)

SET AUTHREC PRINCIPAL('app') OBJTYPE(QMGR) AUTHADD(CONNECT,INQ,ALTUSR)

* When enabled, the following exception is thrown when running in OCP
*   AMQXR0033E: A connection from 10.129.0.23 for client identifier 'ID:a073664b-a901-46e5-a989-8d476fa4a023:1' was rejected for channel SYSTEM.DEF.AMQP because of CONNAUTH or CHLAUTH rule configuration. MQCC 2, MQRC 2330 MQRC_CODED_CHAR_SET_ID_ERROR
* SET CHLAUTH('SYSTEM.DEF.AMQP') TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(CHANNEL) CHCKCLNT({{ .ChckClnt }}) DESCR('Allows connection via AMQP channel') ACTION(REPLACE)

SET AUTHREC PROFILE('SYSTEM.BASE.TOPIC') PRINCIPAL('app') OBJTYPE(TOPIC) AUTHADD(PUB,SUB)
SET AUTHREC PROFILE('SYSTEM.DEFAULT.MODEL.QUEUE') PRINCIPAL('app') OBJTYPE(QUEUE) AUTHADD(PUT,DSP)

ALTER CHANNEL(SYSTEM.DEF.AMQP) CHLTYPE(AMQP) MCAUSER('app')

* Disable channel authentication checking
* ALTER QMGR CHLAUTH(DISABLED) CONNAUTH('')
* REFRESH SECURITY TYPE(CONNAUTH)

* Start AMQP service
START SERVICE(SYSTEM.AMQP.SERVICE)
START CHANNEL(SYSTEM.DEF.AMQP)

* https://www.ibm.com/docs/en/ibm-mq/8.0?topic=80-channel-authentication
* https://www.ibm.com/docs/en/ibm-mq/8.0?topic=commands-set-chlauth
* http://www.mqseries.net/phpBB2/viewtopic.php?t=77876&sid=36500d018457a44f5b3869bb50adb497
ALTER QMGR CHLAUTH(DISABLED)
