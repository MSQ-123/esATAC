UnzipAndMerge <-R6Class(
    classname = "UnzipAndMerge",
    inherit = BaseProc,
    public = list(
        initialize = function(fastqInput1, fastqInput2=NULL,fastqOutput1=NULL,fastqOutput2=NULL,interleave = FALSE,editable = FALSE){
            super$initialize("UnzipAndMerge",editable,list())
            private$paramlist[["interleave"]]<-interleave
            if(interleave){
                private$singleEnd<-FALSE
                private$paramlist[["fastqInput1"]]<-fastqInput1
                for(i in 1:length(private$paramlist[["fastqInput1"]])){
                    private$checkFileExist(private$paramlist[["fastqInput1"]][i]);
                }
                if(!is.null(fastqOutput1)){
                    private$paramlist[["fastqOutput1"]]<-fastqOutput1
                    private$checkFileCreatable(private$paramlist[["fastqOutput1"]])
                }else{
                    private$paramlist[["fastqOutput1"]]<-file.path(.obtainConfigure("tmpdir"),basename(private$paramlist[["fastqInput1"]][1]))
                    private$paramlist[["fastqOutput1"]]<-private$removeCompressSuffix(private$paramlist[["fastqOutput1"]])
                }
            }else{
                if(is.null(fastqInput2)){
                    private$singleEnd<-TRUE
                    private$paramlist[["fastqInput1"]]<-fastqInput1
                    for(i in 1:length(private$paramlist[["fastqInput1"]])){
                        private$checkFileExist(private$paramlist[["fastqInput1"]][i]);
                    }
                    if(!is.null(fastqOutput1)){
                        private$paramlist[["fastqOutput1"]]<-fastqOutput1
                        private$checkFileCreatable(private$paramlist[["fastqOutput1"]])
                    }else{
                        private$paramlist[["fastqOutput1"]]<-file.path(.obtainConfigure("tmpdir"),basename(private$paramlist[["fastqInput1"]][1]))
                        private$paramlist[["fastqOutput1"]]<-private$removeCompressSuffix(private$paramlist[["fastqOutput1"]])
                    }
                    
                }else{
                    private$singleEnd<-FALSE
                    private$paramlist[["fastqInput1"]]<-fastqInput1
                    for(i in 1:length(private$paramlist[["fastqInput1"]])){
                        private$checkFileExist(private$paramlist[["fastqInput1"]][i]);
                    }
                    private$paramlist[["fastqInput2"]]<-fastqInput2
                    if(length(private$paramlist[["fastqInput1"]])!=length(private$paramlist[["fastqInput2"]])){
                        stop("The number of pair-end fastq files should be equal.")
                    }
                    for(i in 1:length(private$paramlist[["fastqInput2"]])){
                        private$checkFileExist(private$paramlist[["fastqInput2"]][i]);
                    }
                    if(!is.null(fastqOutput1)){
                        private$paramlist[["fastqOutput1"]]<-fastqOutput1
                        private$checkFileCreatable(private$paramlist[["fastqOutput1"]])
                    }else{
                        private$paramlist[["fastqOutput1"]]<-file.path(.obtainConfigure("tmpdir"),basename(private$paramlist[["fastqInput1"]][1]))
                        private$paramlist[["fastqOutput1"]]<-private$removeCompressSuffix(private$paramlist[["fastqOutput1"]])
                    }
                    if(!is.null(fastqOutput2)){
                        private$paramlist[["fastqOutput2"]]<-fastqOutput2
                        private$checkFileCreatable(private$paramlist[["fastqOutput2"]])
                    }else{
                        private$paramlist[["fastqOutput2"]]<-file.path(.obtainConfigure("tmpdir"),basename(private$paramlist[["fastqInput2"]][1]))
                        private$paramlist[["fastqOutput2"]]<-private$removeCompressSuffix(private$paramlist[["fastqOutput2"]])
                    }
                }
            }
            
            private$paramValidation()


        }
    ),
    private = list(
        processing = function(){
            if(private$singleEnd||(!private$singleEnd&&private$paramlist[["interleave"]])){
                fileNumber<-length(private$paramlist[["fastqInput1"]])
                private$decompress(private$paramlist[["fastqInput1"]][1],private$paramlist[["fastqOutput1"]])
                if(fileNumber>1){
                    for(i in 2:fileNumber){
                        tempfastqfile<-private$decompressFastq(private$paramlist[["fastqInput1"]][i],dirname(private$paramlist[["fastqOutput1"]]));
                        file.append(private$paramlist[["fastqOutput1"]],tempfastqfile)
                        if(tempfastqfile!=private$paramlist[["fastqInput1"]][i]){
                            unlink(tempfastqfile)
                        }
                    }
                }
            }else{
                fileNumber<-length(private$paramlist[["fastqInput1"]])
                private$decompress(private$paramlist[["fastqInput1"]][1],private$paramlist[["fastqOutput1"]])
                private$decompress(private$paramlist[["fastqInput2"]][1],private$paramlist[["fastqOutput2"]])
                if(fileNumber>1){
                    for(i in 2:fileNumber){
                        tempfastqfile<-private$decompressFastq(private$paramlist[["fastqInput1"]][i],dirname(private$paramlist[["fastqOutput1"]]));
                        file.append(private$paramlist[["fastqOutput1"]],tempfastqfile)
                        if(tempfastqfile!=private$paramlist[["fastqInput1"]][i]){
                            unlink(tempfastqfile)
                        }
                        tempfastqfile<-private$decompressFastq(private$paramlist[["fastqInput2"]][i],dirname(private$paramlist[["fastqOutput2"]]));
                        file.append(private$paramlist[["fastqOutput2"]],tempfastqfile)
                        if(tempfastqfile!=private$paramlist[["fastqInput2"]][i]){
                            unlink(tempfastqfile)
                        }
                    }
                }
            }
        },
        checkRequireParam = function(){
            if(is.null(private$paramlist[["fastqInput1"]])){
                stop("fastqInput1 is required.")
            }
            if(private$paramlist[["interleave"]]&&private$singleEnd){
                stop("Single end data should not be interleave")
            }
        },
        checkAllPath = function(){
            private$checkFileCreatable(private$paramlist[["fastqOutput1"]])
            private$checkFileCreatable(private$paramlist[["fastqOutput2"]])
        },
        decompressFastq = function(filename,destpath){
            destname<-file.path(destpath,basename(filename))
            private$writeLog(paste0("processing file:"))
            private$writeLog(sprintf("source:%s",filename))
            private$writeLog(sprintf("destination:%s",destname))
            if(isBzipped(filename)){
                destname<-gsub(sprintf("[.]%s$", "bz2"), "", destname, ignore.case=TRUE)
                return(bunzip2(filename,destname=destname,overwrite=TRUE,remove=FALSE))
            }else if(isGzipped(filename)){
                destname<-gsub(sprintf("[.]%s$", "gz"), "", destname, ignore.case=TRUE)
                return(gunzip(filename,destname=destname,overwrite=TRUE,remove=FALSE))
            }else{
                return(filename)
            }


        },
        decompress = function(filename,destname){
            private$writeLog(paste0("processing file:"))
            private$writeLog(sprintf("source:%s",filename))
            private$writeLog(sprintf("destination:%s",destname))
            if(isBzipped(filename)){
                return(bunzip2(filename,destname=destname,overwrite=TRUE,remove=FALSE))
            }else if(isGzipped(filename)){
                return(gunzip(filename,destname=destname,overwrite=TRUE,remove=FALSE))
            }else if(normalizePath(dirname(filename))!=normalizePath(dirname(destname))||
                     basename(filename)!=basename(destname)){
                file.copy(filename,destname,overwrite = TRUE)
            }

            return(destname)
        },
        removeCompressSuffix= function(filename){
            filename<-gsub(sprintf("[.]%s$", "bz2"), "", filename, ignore.case=TRUE)
            filename<-gsub(sprintf("[.]%s$", "gz"), "", filename, ignore.case=TRUE)
            filename<-gsub(sprintf("[.]%s$", "fastq"), "", filename, ignore.case=TRUE)
            filename<-gsub(sprintf("[.]%s$", "fq"), "", filename, ignore.case=TRUE)
            filename<-paste0(filename,".",self$getProcName(),".fq")
            return(filename)
        }
    )

)





atacUnzipAndMerge<- function(fastqInput1, fastqInput2=NULL,
                             fastqOutput1=NULL,fastqOutput2=NULL,
                             interleave = FALSE){
    atacproc <- UnzipAndMerge$new(fastqInput1 = fastqInput1,
                                  fastqInput2 = fastqInput2,
                                  fastqOutput1 = fastqOutput1,
                                  fastqOutput2 = fastqOutput2,
                                  interleave = interleave);
    atacproc$process();
    return(atacproc);
}