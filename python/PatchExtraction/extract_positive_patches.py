#!/usr/bin/python
import sys
from PositivePatchExtractor import PositivePatchExtractor

if __name__ == '__main__':
  if len( sys.argv ) < 4:
    print 'Usage %s <configFile> <baseInputFolder> <outputFolder>' % sys.argv[ 0 ]
    sys.exit( 1 )
  ppe = PositivePatchExtractor(sys.argv[1], sys.argv[2], sys.argv[3])
