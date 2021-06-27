#grep '^[0-9]' ./train/disdrug.lsn | awk '{print $1"-"$2"\tdisdrug\t"$1"-"$2"\t"$0}' > ./train/drugDis.train
grep '^[0-9]' ./train/disdrug.lsn | awk '{text ="";for (num=3;num<=NF;num++){text=text" "$num};print $1"-"$2"\tdisdrug\t"text}' > ./train/drugDis.train
#grep '^[0-9]' ./train/others.lsn | awk '{print $1"-"$2"\tothers\t"$1"-"$2"\t"$0}' >> ./train/drugDis.train
grep '^[0-9]' ./train/others.lsn | awk '{text ="";for (num=3;num<=NF;num++){text=text" "$num};print $1"-"$2"\tothers\t"text}' >> ./train/drugDis.train


mallet import-file --input ./train/drugDis.train --output disdrug.mallet
#native bayes
###mallet train-classifier --input disdrug.mallet --output-classifier disdrug.classifier
#--trainer MaxEnt
mallet train-classifier --input disdrug.mallet --trainer MaxEnt --output-classifier disdrug.classifier
#awk '{print $1"-"$2"\t"$0}' ./test1  >test2
awk '{text ="";for (num=3;num<=NF;num++){text=text" "$num};print text}' ./20101201.txt  >test2
####
#csv2classify  --input blank --output -  --classifier disdrug.classifier
###
csv2classify  --input test2 --output -  --classifier disdrug.classifier | awk '{print NR$0}' | awk '{if($3>=0.2) print $1}' > cadidateLines
cat cadidateLines

a=0
while read line
do a=$(($a+1));
done < "cadidateLines"
echo "significant records:$a";

if [ $a -gt 0 ]
then
    python lineExtractor.py
    sh ./files.sh
	cat activeLearning.log
fi

