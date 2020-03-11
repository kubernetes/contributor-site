#! /usr/bin/env python
from __future__ import print_function
import sys,os,subprocess,signal,glob
class gencontent(object):
    __slots__ = ["val"]
    def __init__(self, value=''):
        self.val = value
    def setValue(self, value=None):
        self.val = value
        return value
    def postinc(self,inc=1):
        tmp = self.val
        self.val += inc
        return tmp

def GetVariable(name, local=locals()):
    if name in local:
        return local[name]
    if name in globals():
        return globals()[name]
    return None

def Make(name, local=locals()):
    ret = GetVariable(name, local)
    if ret is None:
        ret = gencontent(0)
        globals()[name] = ret
    return ret

def GetValue(name, local=locals()):
    variable = GetVariable(name,local)
    if variable is None or variable.val is None:
        return ''
    return variable.val

def Array(value):
    if isinstance(value, list):
        return value
    if isinstance(value, basestring):
        return value.strip().split(' ')
    return [ value ]

def Glob(value):
    ret = glob.glob(value)
    if (len(ret) < 1):
        ret = [ value ]
    return ret

class Expand(object):
    @staticmethod
    def at():
        if (len(sys.argv) < 2):
            return []
        return  sys.argv[1:]
    @staticmethod
    def hash():
        return  len(sys.argv)-1
    @staticmethod
    def colonMinus(name, value=''):
        ret = GetValue(name)
        if (ret is None or ret == ''):
            ret = value
        return ret

# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
_rc0 = subprocess.call(["set","-o","errexit"],shell=True)
_rc0 = subprocess.call(["set","-o","nounset"],shell=True)
_rc0 = subprocess.call(["set","-o","pipefail"],shell=True)
_rc0 = subprocess.call(["readonly","DEBUG="+Expand.colonMinus("DEBUG","\"false\"")],shell=True)
_rc0 = subprocess.call(["readonly","REPO_ROOT="+os.popen("git rev-parse --show-toplevel").read().rstrip("\n")],shell=True)
_rc0 = subprocess.call(["readonly","CONTENT_DIR="+str(REPO_ROOT.val)+"/content"],shell=True)
_rc0 = subprocess.call(["readonly","TEMP_DIR="+str(REPO_ROOT.val)+"/_tmp"],shell=True)
_rc0 = subprocess.call(["readonly","EXTERNAL_SOURCES="+Expand.colonMinus("EXTERNAL_SOURCES","\""+str(REPO_ROOT.val)+"/external-sources\"")],shell=True)
_rc0 = subprocess.call(["readonly","HEADER_TMPLT=---\ntitle: __TITLE__\n---\n"],shell=True)
os.chdir(str(REPO_ROOT.val))
def cleanup () :
    global TEMP_DIR

    subprocess.call(["rm","-rf",str(TEMP_DIR.val)],shell=True)

if (str(DEBUG.val) == "false" ):
    signal.signal(signal.SIGEXIT,cleanup)

# init_src
# Initializes source repositories by pulling the latest content. If the repo
# is already present, fetch the latest content from the master branch.
# Args:
# $1 - git repo to be cloned/fetched
# $2 - path to destination directory for cloned repo
def init_src (_p1,_p2) :
    if (not os.path.isdir(str(_p2)) ):
        print("Cloning "+str(_p1))
        subprocess.call(["git","clone","--depth=1",str(_p1),str(_p2)],shell=True)
    elif (os.popen("git -C \""+str(_p2)+"\" rev-parse --show-toplevel").read().rstrip("\n") == str(_p2) ):
        print("Syncing with latest content from master.")
        subprocess.call(["git","-C",str(_p2),"checkout","."],shell=True)
        subprocess.call(["git","-C",str(_p2),"pull"],shell=True)
    else:
        print("Destination "+str(_p2)+" already exists and is not a git repository.")
        exit(1)

# find_md_files
# Returns all markdown files within a directory
# Args:
# $1 - Path to directory to search for markdown files
def find_md_files (_p1) :
    _rcr1, _rcw1 = os.pipe()
    if os.fork():
        os.close(_rcw1)
        os.dup2(_rcr1, 0)
        subprocess.call(["sort","-z"],shell=True)
    else:
        os.close(_rcr1)
        os.dup2(_rcw1, 1)
        subprocess.call(["find",str(_p1),"-type","f","-name","*.md","-print0"],shell=True)
        sys.exit(0)


# process_content
# Updates the links within a markdown file so that they will resolve within
# the Hugo generated site. If the link is a file reference, it is expanded
# so the path is from the root of the git repo. The links are then passed
# to gen_link which will determine if the link references content within one
# of the sources being synced to the content directory. If so, update the link
# with the path that it will be after being copied over. This includes removing
# the extension and if the file is a README, trim it (README's function as the
# root page.) If the link references something not within the content that is
# being copied over, but still within one of the kubernetes projects update it to
# to use the git.k8s.io shortener.
# Example:
#   Repo: https://github.com/kubernetes/community
#   Content to be synced: /contributors/guide -> /guide
#   Markdown file: /contributors/guide/README.md
#   Links:
#   ./bug-bounty.md -> /guide/bug-bounty
#   contributor-cheatsheet/README.md -> /guide/contributor-cheatsheet
#   ../../sig-list.md -> https://git.k8s.io/community/sig-list.md
#   /contributors/devel/README.md -> https://git.k8s.io/community/contributors/devel/README.md
#   http://git.k8s.io/cotributors/guide/collab.md -> /guide/collab
#   https://github.com/kubernetes/enhancements/tree/master/keps -> https://git.k8s.io/enhancements/keps
#
# Args:
# $1 - Full path to markdown file to be processed
# $2 - Full file system path to root of cloned git repo
# $3 - srcs array name
# $4 - dest array name
def process_content (_p1,_p2,_p3,_p4) :
    global match

    Make("inline_link_matches").setValue("()")
    ref_link_matches=gencontent("()")
    _rc0 = subprocess.call("mapfile" + " " + "-t" + " " + "inline_link_matches",shell=True,stdin=file("<(grep -o -i -P \\[(?!a\\-z0\\-9).+?\\]\\((?!mailto|\\S+?@|<|>|\\?|\\!|@|#|\\$|%|\\^|&|\\*|\\))\\K\\S+?(?=\\)) "+str(_p1)+")",'rb'))
    < <(grep -o -i -P '\[(?!a\-z0\-9).+?\]\((?!mailto|\S+?@|<|>|\?|\!|@|#|\$|%|\^|&|\*|\))\K\S+?(?=\))' "$1")
    if (dir().count("inline_link_matches") != 0 ):
        for Make("match").val in Array(inline_link_matches.val[@] ]):
            Make("replacement_link").setValue()
            if (_rcr8, _rcw8 = os.pipe()
        if os.fork():
            os.close(_rcw8)
            os.dup2(_rcr8, 0)
            subprocess.call(["grep","-i","-q","^http"],shell=True)
        else:
            os.close(_rcr8)
            os.dup2(_rcw8, 1)
            print(match.val)
            sys.exit(0) ):
            Make("replacement_link").setValue(match.val)
            else:
            Make("replacement_link").setValue(os.popen("expand_path \""+str(_p1)+"\" \""+str(match.val)+"\" \""+str(_p2)+"\"").read().rstrip("\n"))
            Make("replacement_link").setValue(os.popen("gen_link \""+str(replacement_link.val)+"\" \""+str(_p2)+"\" \""+str(_p3)+"\" \""+str(_p4)+"\"").read().rstrip("\n"))
            if (str(match.val) != str(replacement_link.val) ):
                print("Update link: File: "+str(_p1)+" Original: "+str(match.val)+" Updated: "+str(replacement_link.val))
            subprocess.call(["sed","-i","-e","s|]("+str(match.val)+")|]("+str(replacement_link.val)+")|g",str(_p1)],shell=True)
            _rc0 = subprocess.call("mapfile" + " " + "-t" + " " + "ref_link_matches",shell=True,stdin=file("<(grep -o -i -P ^\\[.+\\]:\\s*(?!|mailto|\\S+?@|<|>|\\?|\\!|@|#|\\$|%|\\^|&|\\*)\\K\\S+$ "+str(_p1)+")",'rb'))
                   < <(grep -o -i -P '^\[.+\]:\s*(?!|mailto|\S+?@|<|>|\?|\!|@|#|\$|%|\^|&|\*)\K\S+$' "$1")
            if (dir().count("ref_link_matches") != 0 ):
                for Make("match").val in Array(ref_link_matches.val[@] ]):
            Make("replacement_link").setValue()
            if (_rcr6, _rcw6 = os.pipe()
            if os.fork():
                os.close(_rcw6)
            os.dup2(_rcr6, 0)
            subprocess.call(["grep","-i","-q","^http"],shell=True)
            else:
            os.close(_rcr6)
            os.dup2(_rcw6, 1)
            print(match.val)
            sys.exit(0) ):
            Make("replacement_link").setValue(match.val)
            else:
            Make("replacement_link").setValue(os.popen("expand_path \""+str(_p1)+"\" \""+str(match.val)+"\" \""+str(_p2)+"\"").read().rstrip("\n"))
            Make("replacement_link").setValue(os.popen("gen_link \""+str(replacement_link.val)+"\" \""+str(_p2)+"\" \""+str(_p3)+"\" \""+str(_p4)+"\"").read().rstrip("\n"))
            if (str(match.val) != str(replacement_link.val) ):
                print("Update link: File: "+str(_p1)+" Original: "+str(match.val)+" Updated: "+str(replacement_link.val))
            subprocess.call(["sed","-i","-e","s|]:\s*"+str(match.val)+"|]: "+str(replacement_link.val)+"|g",str(_p1)],shell=True)
            if (os.popen("head -n 1 \""+str(_p1)+"\"").read().rstrip("\n") != "---" ):
                subprocess.call(["insert_header",str(_p1)],shell=True)

                # expand_paths
                # Generates (or expands) the full path relative to the root of the directory if
                # it is valid path, otherwise return the passed path assuming it in reference
                # to something else.
                # Args:
                # $1 - path to file containing relative link
                # $2 - path to be expanded
                # $3 - prefix to repo trim from path
def expand_path (_p1,_p2,_p3) :

    Make("dirpath").setValue()
    filename=gencontent()
    expanded_path=gencontent()
    dirpath=gencontent(os.popen(" (cd \""+os.popen("dirname \""+str(_p1)+"\"").read().rstrip("\n")+"\" && readlink -f \""+os.popen("dirname \""+str(_p2)+"\"").read().rstrip("\n")+"\"").read().rstrip("\n")+" ||           dirname "+str(_p2)+" )")
    filename=gencontent(os.popen("basename \""+str(_p2)+"\"").read().rstrip("\n"))
    if str(dirpath.val) == "." or str(dirpath.val) == "/":
        Make("dirpath").setValue()
    expanded_path=gencontent(str(dirpath.val)+"/"+str(filename.val))
    if (_rcr2, _rcw2 = os.pipe()
    if os.fork():
        os.close(_rcw2)
    os.dup2(_rcr2, 0)
    subprocess.call(["grep","-q","-P","^\.?\/?"+str(expanded_path.val)],shell=True)
    else:
    os.close(_rcr2)
    os.dup2(_rcw2, 1)
    print(_p2)
    sys.exit(0) ):
    print(expanded_path.val)
else:
print(expanded_path.val##"_p3")

# gen_link
# Generates the correct link for the destination location. If it is a url that
# references content that will be synced, convert it to a path.
# $1 - Link String
# $2 - Full file system path to root of cloned git repo
# $3 - Array of sources (passed by reference)
# $4 - Array of destinations (passed by reference)
def gen_link (_p1,_p2,_p3,_p4) :
    global i
    global internal_link
    global org

    "-n"
    Make("glsrcs").setValue(_p3)
    "-n"
    gldsts=gencontent(_p4)
    generated_link=gencontent()
    generated_link=gencontent(_p1)
    # If it was previously an "external" link but now local to the contributor site
    # update the link by trimming the url portion.
    # TODO: Improve support for handling additional external repos.
    # Detection is a problem for non kubernetes orgs. New org names must be
    # appended for generation of correct url rewrites. It may need to be further
    # updated if the external org/repo uses their own domain shortener similar to
    # git.k8s.io.
    if (_rcr4, _rcw4 = os.pipe()
    if os.fork():
        os.close(_rcw4)
    os.dup2(_rcr4, 0)
    subprocess.call(["grep","-q","-i","-E","https?:\/\/((sigs|git)\.k8s\.io|(www\.)?github\.com\/(kubernetes(-(client|csi|incubator|sigs))?|cncf))"],shell=True)
    else:
    os.close(_rcr4)
    os.dup2(_rcr4, 0)
    subprocess.call(["grep","-q","-i","-E","https?:\/\/((sigs|git)\.k8s\.io|(www\.)?github\.com\/(kubernetes(-(client|csi|incubator|sigs))?|cncf))"],shell=True)
    else:
    os.close(_rcr4)
    os.dup2(_rcw4, 1)
    print(generated_link.val)
    sys.exit(0) ):
    "i"
    Make("i").setValue(0)
    while ((i.val < Expand.hash()glsrcs[@].val)):
        Make("repo").setValue()
        Make("src").setValue()
        Make("repo").setValue(os.popen("echo \""+str(glsrcs.val[i] ])+"\" | cut -d '/' -f2").read().rstrip("\n")+"/"+os.popen("echo \""+str(glsrcs.val[i] ])+"\" | cut -d '/' -f3").read().rstrip("\n"))
        Make("src").setValue(glsrcs.val[i] ]#/repo.val)
        if (_rcr7, _rcw7 = os.pipe()
        if os.fork():
            os.close(_rcw7)
        os.dup2(_rcr7, 0)
        subprocess.call(["grep","-q","-i","-E","/"+str(repo.val)+"(/(blob|tree)/master)?"+str(src.val)],shell=True)
        else:
        os.close(_rcr7)
        os.dup2(_rcw7, 1)
        print(generated_link.val)
        sys.exit(0) ):
        Make("generated_link").setValue(src.val)
        break
        Make("i").postinc()
# If the link's path matches against one of the source locations, update it
# to use the matching destination path. If no match is found, expand to
# a full github.com/$org/$repo address
if (_rcr3, _rcw3 = os.pipe()
if os.fork():
    os.close(_rcw3)
os.dup2(_rcr3, 0)
subprocess.call(["grep","-q","-i","-v","^http"],shell=True)
else:
os.close(_rcr3)
os.dup2(_rcw3, 1)
print(generated_link.val)
sys.exit(0) ):
"internal_link"
Make("internal_link").setValue("false")
"i"
Make("i").setValue(0)
while ((i.val < Expand.hash()glsrcs[@].val)):
    Make("repo").setValue()
    Make("src").setValue()
    Make("repo").setValue(os.popen("echo \""+str(glsrcs.val[i] ])+"\" | cut -d '/' -f2").read().rstrip("\n")+"/"+os.popen("echo \""+str(glsrcs.val[i] ])+"\" | cut -d '/' -f3").read().rstrip("\n"))
    Make("src").setValue(glsrcs.val[i] ]#/repo.val)
    if (_rcr7, _rcw7 = os.pipe()
    if os.fork():
        os.close(_rcw7)
    os.dup2(_rcr7, 0)
    subprocess.call(["grep","-i","-q","^"+str(src.val)],shell=True)
    else:
    os.close(_rcr7)
    os.dup2(_rcw7, 1)
    print(generated_link.val)
    sys.exit(0) ):
    Make("generated_link").setValue(generated_link.val/src.val/gldsts.val[i] ])
    if (_rcr8, _rcw8 = os.pipe()
    if os.fork():
        os.close(_rcw8)
    os.dup2(_rcr8, 0)
    subprocess.call(["grep","-i","-q","readme\\.md"],shell=True)
    else:
    os.close(_rcr8)
    os.dup2(_rcw8, 1)
    subprocess.call(["basename",str(generated_link.val)],shell=True)
    sys.exit(0) ):
    # shellcheck disable=SC2001 # prefer sed for native ignorecase
    Make("generated_link").setValue(os.popen("echo \""+str(generated_link.val)+"\" | sed -e 's|/readme.md|/|I'").read().rstrip("\n"))
    Make("internal_link").setValue("true")
    break
    else:
    # shellcheck disable=SC2001 # prefer sed for native ignorecase
    Make("generated_link").setValue(os.popen("echo \""+str(generated_link.val)+"\" | sed -e 's|.md||I'").read().rstrip("\n"))
    Make("internal_link").setValue("true")
    break
Make("i").postinc()
if (str(internal_link.val) == "false" ):
    "org"
    Make("org").setValue(os.popen("echo \""+str(_p2)+"\" | rev | cut -d '/' -f2 | rev").read().rstrip("\n"))
    # reverse the string to trim from the "right"
    Make("generated_link").setValue("https://github.com/"+str(org.val)+"/"+os.popen("basename \""+str(_p2)+"\"").read().rstrip("\n")+"/blob/master"+str(generated_link.val))
print(generated_link.val)

# insert_header
# Inserts the base hugo header needed to render a page correctly. This should
# only be called if -no- header is already detected.
# $1 - The full path to the markdown file.
def insert_header (_p1) :
    global filename
    global title
    global HEADER_TMPLT

    "title"
    "filename"
    filename=gencontent(os.popen("basename \""+str(_p1)+"\"").read().rstrip("\n"))
    # If its README, assume the title should be that of the parent dir.
    # Otherwise use the name of the file.
    if (str(filename.val,,) == "readme.md" or str(filename.val,,) == "_index.md" ):
        Make("title").setValue(os.popen("basename \""+os.popen("dirname \""+str(_p1)+"\"").read().rstrip("\n")+"\"").read().rstrip("\n"))
    else:
        Make("title").setValue(filename.val%.md)
        title=gencontent(os.popen("echo \""+str(title.val//[-|_]/ )+"\" | sed -r 's/<./U&/g'").read().rstrip("\n"))
        _rc0 = subprocess.call(["sed","-i","1i"+str(HEADER_TMPLT.val//__TITLE__/str(title.val)),str(_p1)],shell=True)
        print("Header inserted into: "+str(_p1))

    def main () :
        global TEMP_DIR
        global EXTERNAL_SOURCES
        global repo
        global org
        global IFS
        global src
        global dst
        global file
        global filename
        global CONTENT_DIR

        subprocess.call(["mkdir","-p",str(TEMP_DIR.val)],shell=True)
        repos=gencontent("()")
        # array of kubernetes repos containing content to be synced
        srcs=gencontent("()")
        # array of sources of content to be synced
        dsts=gencontent("()")
        # array of destinations for the content to be synced to
        # Files within the EXTERNAL_SOURCES directory should be csv formatted with the
        # directory being the GitHub org and name of the file being the repo name
        # (e.g. kubernetes/community), and the  content being the path to the content
        # to be synced within the repo to the to the destination within the HUGO
        # content directory.
        # Example:
        # file-path: external-sources/kubernetes/community
        # "/contributors/guide", "/guide"
        _rc0 = subprocess.call(["shopt","-s","globstar"],shell=True)
        for Make("repo").val in Glob(str(EXTERNAL_SOURCES.val)+"/**"):
            if (os.path.isfile(str(repo.val)) ):
                Make("repos").setValue("("+str(repo.val)+")")
    _rc0 = subprocess.call(["shopt","-u","globstar"],shell=True)
    # populate the arrays with information parsed from files in ${EXTERNAL_SOURCES}
    for Make("repo").val in Array(repos.val[@] ]):
        "org"
    Make("org").setValue(os.popen("basename \""+os.popen("dirname \""+str(repo.val)+"\"").read().rstrip("\n")+"\"").read().rstrip("\n"))
    # shellcheck disable=SC2094 # false detection on read/write to $repo at the same time
    < "$repo"while (if not Make("IFS").setValue(","):
        str(src.val) != ''):
    Make("srcs").setValue("(/"+str(org.val)+"/"+os.popen("basename \""+str(repo.val)+"\"").read().rstrip("\n")+os.popen("echo \""+str(src.val)+"\" | sed -e 's/^"//g;s/"$//g'").read().rstrip("\n")+")")
    Make("dsts").setValue("("+os.popen("echo \""+str(dst.val)+"\" | sed -e 's/^"//g;s/"$//g'").read().rstrip("\n")+")") < "$repo"
init_src("https://github.com/"+str(org.val)+"/"+os.popen("basename \""+str(repo.val)+"\"").read().rstrip("\n")+".git", str(TEMP_DIR.val)+"/"+str(org.val)+"/"+os.popen("basename \""+str(repo.val)+"\"").read().rstrip("\n"))
Make("i").setValue(0)
while (i.val < Expand.hash()srcs[@].val):
    Make("repo").setValue()
    Make("src").setValue()
    Make("repo").setValue(os.popen("echo \""+str(srcs.val[i] ])+"\" | cut -d '/' -f2").read().rstrip("\n")+"/"+os.popen("echo \""+str(srcs.val[i] ])+"\" | cut -d '/' -f3").read().rstrip("\n"))
    Make("src").setValue(srcs.val[i] ]#/repo.val)
    < <(find_md_files "${TEMP_DIR}${srcs[i]}")while (Make("IFS").setValue()):
        process_content(file.val, str(TEMP_DIR.val)+"/"+str(repo.val), "srcs", "dsts")
        # if the source file is a readme, or the destination is a singular file it
        # should be evaluated and if needed renamed.
        if (if not os.popen("basename \""+str(file.val,,)+"\"").read().rstrip("\n") == "readme.md":
            _rcr8, _rcw8 = os.pipe()
        if os.fork():
            os.close(_rcw8)
        os.dup2(_rcr8, 0)
        subprocess.call(["grep","-q","\.md"+"$"],shell=True)
        else:
        os.close(_rcr8)
        os.dup2(_rcw8, 1)
        print(dsts.val[i] ])
        sys.exit(0) ):
        Make("filename").setValue()
        # if file is a readme and the destination is NOT a file, assume it is
        # the "root" of a directory.
        if (if os.popen("basename \""+str(file.val,,)+"\"").read().rstrip("\n") == "readme.md":
        _rcr10, _rcw10 = os.pipe()
        if os.fork():
            os.close(_rcw10)
            os.dup2(_rcr10, 0)
            subprocess.call(["grep","-v","-q","\.md"+"$"],shell=True)
        else:
            os.close(_rcr10)
            os.dup2(_rcw10, 1)
            print(dsts.val[i] ])
            sys.exit(0) ):
            Make("filename").setValue(os.popen("dirname \""+str(file.val)+"\"").read().rstrip("\n")+"/_index.md")
            else:
            # If not a readme, assume its a singular file that should be moved.
            # Because it is renamed in place before syncing, the srcs array must
            # be updated to reflect its rename. This is over-eager for most use
            # cases, but should take care of everything.
            Make("filename").setValue(os.popen("dirname \""+str(file.val)+"\"").read().rstrip("\n")+"/"+os.popen("basename \""+str(dsts.val[i] ])+"\"").read().rstrip("\n"))
            Make("srcs").val[i.setValue(os.popen("dirname \""+str(srcs.val[i] ])+"\"").read().rstrip("\n")+"/"+os.popen("basename \""+str(dsts.val[i] ])+"\"").read().rstrip("\n"))
            # checks if both the source and destination would be the same
            if (str(file.val) != str(filename.val) ):
                subprocess.call(["mv",str(file.val),str(filename.val)],shell=True)
            print("Renamed: "+str(file.val)+" to "+str(filename.val)) < <(find_md_files "${TEMP_DIR}${srcs[i]}")
            Make("i").postinc()
            print("Copying to hugo content directory.")
            Make("i").setValue(0)
while (i.val < Expand.hash()srcs[@].val):
    if (os.path.isdir(str(TEMP_DIR.val)+str(srcs.val[i] ])) ):
    # OWNERS files are excluded when copied to prevent potential overwriting of desired
    # owner config.
        subprocess.call(["rsync","-av",str(TEMP_DIR.val)+str(srcs.val[i] ])+"/",str(CONTENT_DIR.val)+str(dsts.val[i] ]),"--exclude","OWNERS"],shell=True)
    elif (os.path.isfile(str(TEMP_DIR.val)+str(srcs.val[i] ])) ):
    subprocess.call(["rsync","-av",str(TEMP_DIR.val)+str(srcs.val[i] ]),str(CONTENT_DIR.val)+str(dsts.val[i] ]),"--exclude","OWNERS"],shell=True)
    Make("i").postinc()
    print("Content synced.")

    main(Expand.at())
