# -*- coding: utf-8 -*-
"""
Created on Mon 23 2017

@author: adotti
"""
import sys
if len(sys.argv)<2:
    print 'usage:',sys.argv[0],'<list.json>'
    print '     <list.json> is the simplified list of tasks json file'
    exit(0)

templatefile='jobs-template.json'
jobsfile=sys.argv[1]

import json
import copy

_f1=file(templatefile)
_f2=file(jobsfile)
_template=json.load(_f1)
_tasks_list=json.load(_f2)

_job=_template[u'job_specifications'][0]

_id=_tasks_list.keys()[0]
_job[u'id']=_id
_task=(_job[u'tasks'][0])
_job[u'tasks']=[]

for _cmd in _tasks_list[_id]:
    _t=copy.copy(_task)
    _t[u'command']=_cmd
    _job[u'tasks'].append(_t)

_finalout={ u'job_specifications': [ _job ] }
_of=file("gen-jobs.json","w")
json.dump(_finalout,_of,indent=1)
_of.close()
_f1.close()
_f2.close()

