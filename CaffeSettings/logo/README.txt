Steps:
--------------------------------------------------------------
* Copy paste this folder to a fast SSD drive. 
* Populate folder 'input' with training/test data from ruby script 'create_dataset_split.rb'.
* Modify prototxt files as needed - if finetuning imagenet, no change is necessary

* Run 'create_logo.sh' to create leveldb
* Run 'finetune_logo.sh' to finetune imagenet network to train on this dataset
* If not finetuning imagenet but starting from scratch, use 'train_log.sh' script instead
* To test model in patches extracted from videos (using sliding window script), run 'test_patches.sh <testFolderName>'

Output:
--------------------------------------------------------------
* Model will be saved in the same directory as 'train_logo.sh' and will be named 'caffe_logo_train_iter_<IterationNumber>'. Intermediate results will be named 'caffe_logo_train_<IterationNumber>.solverstate'.
* Test results will be saved in '<testFolderName>.csv'

Errors:
--------------------------------------------------------------
* If you see error in 'create_logo.sh', it is most likely due to incorrect image dimension (256x256px for imagenet network)
* If you see error in 'train_logo.sh' or 'finetune_logo.sh', it is most likely due to out of disk or memory issue
* If NOT finetuning: Once training starts, if for some reason, we need to restart, we can run 'resume_training.sh' file after editing the '<IterationNumber>' part in that file with the latest intermediate results file.
