#!/usr/bin/env python
"""
get_predictions.py is a clone of classify.py that spits out predictions per folder.

By default it configures and runs the Logo model.
"""
import numpy as np
import os
import sys
import argparse
import glob
import time
from os.path import basename

import caffe


def main(argv):
    pycaffe_dir = os.path.dirname(__file__)

    parser = argparse.ArgumentParser()
    # Required arguments: input and output files.
    parser.add_argument(
        "input_file",
        help="Input image, directory, or npy."
    )
    parser.add_argument(
        "output_file",
        help="Output npy filename."
    )
    # Optional arguments.
    parser.add_argument(
        "--model_def",
        default=os.path.join(pycaffe_dir,
                "../examples/logo2/logo2_deploy.prototxt"),
        help="Model definition file."
    )
    parser.add_argument(
        "--pretrained_model",
        default=os.path.join(pycaffe_dir,
                "../examples/logo2/caffe_logo2_train_iter_5000"),
        help="Trained model weights file."
    )
    parser.add_argument(
        "--gpu",
        action='store_true',
        help="Switch for gpu computation."
    )
    parser.add_argument(
        "--center_only",
        action='store_true',
        help="Switch for prediction from center crop alone instead of " +
             "averaging predictions across crops (default)."
    )
    parser.add_argument(
        "--images_dim",
        default='256,256',
        help="Canonical 'height,width' dimensions of input images."
    )
    parser.add_argument(
        "--mean_file",
        default=os.path.join(pycaffe_dir,
                             'caffe/imagenet/ilsvrc_2012_mean.npy'),
        help="Data set image mean of H x W x K dimensions (numpy array). " +
             "Set to '' for no mean subtraction."
    )
    parser.add_argument(
        "--input_scale",
        type=float,
        default=255,
        help="Multiply input features by this scale before input to net"
    )
    parser.add_argument(
        "--channel_swap",
        default='2,1,0',
        help="Order to permute input channels. The default converts " +
             "RGB -> BGR since BGR is the Caffe default by way of OpenCV."

    )
    parser.add_argument(
        "--ext",
        default='png',
        help="Image file extension to take as input when a directory " +
             "is given as the input file."
    )
    args = parser.parse_args()

    image_dims = [int(s) for s in args.images_dim.split(',')]
    channel_swap = [int(s) for s in args.channel_swap.split(',')]

    # Make classifier.
    classifier = caffe.Classifier(args.model_def, args.pretrained_model,
            image_dims=image_dims, gpu=args.gpu, mean_file=args.mean_file,
            input_scale=args.input_scale, channel_swap=channel_swap)

    if args.gpu:
        print 'GPU mode'

    # Load numpy array (.npy), directory glob (*.jpg), or image file.
    args.input_file = os.path.expanduser(args.input_file)
    # if not directory, complain:
    if os.path.isdir(args.input_file):
        labelFile = open(args.output_file + ".csv",'w')
        notWrittenCSVTopLine = True

        wholeFileList = glob.glob(args.input_file + '/*.' + args.ext)
        oldI = 0
        # larger batch size consumes more memory - about 1.5GB/100 files
        batchSize = 500
        
        start = time.time()
        for i in xrange(batchSize, len(wholeFileList) + batchSize + 1, batchSize):
            fileList = wholeFileList[oldI:i]
            if fileList:
                oldI = i
                inputs = [caffe.io.load_image(im_f) for im_f in fileList]

                print "Classifying %d inputs." % len(inputs)

                # Classify.
                predictions = classifier.predict(inputs, not args.center_only)

                # write the top row label for CSV file
                if notWrittenCSVTopLine:
                    topLineLabel = "Filename"
                    curScores = predictions[0].tolist()
                    for cIdx, cScr in enumerate(curScores):
                        topLineLabel = topLineLabel + ",Class_" + repr(cIdx)
                    labelFile.write(topLineLabel + "\n")
                    notWrittenCSVTopLine = False

                # Expand numpy and save labels in file as well
                for idx, im_f in enumerate(fileList):
                    printStr = basename(im_f)
                    curScores = predictions[idx].tolist()
                    for cIdx, cScr in enumerate(curScores):
                        printStr = printStr + "," + repr(cScr)
                    # curMax = max(curScores)
                    # curClass = curScores.index(curMax)
                    # printStr = basename(im_f) + "," + repr(curMax) + "," + repr(curClass)
                    labelFile.write(printStr + "\n")
                    print printStr
        labelFile.close()
        print "Done in %.2f s." % (time.time() - start)
    else:
        print "Cannot classify - please specify input directory with images"


if __name__ == '__main__':
    main(sys.argv)
