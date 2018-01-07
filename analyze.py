#!/usr/bin/env python
# USAGE: ./analyze.py /path/to/keys.txt

import sys
import re
import string
import argparse


class Data:
    CmdTypes = {
        "quit" : ["save-buffers-kill-emacs", "kill-emacs"],
        "editing" : [
            "self-insert-command", "org-self-insert-command",
            "delete-forward-char", "delete-backward-char",
            "delete-forward-char", "newline", "kill-line",
            "c-electric-backspace", "yank"
        ],
        "navigate" : [
            "next-line", "previous-line", "mwheel-scroll", "right-char",
            "left-char", "forward-paragraph", "backward-paragraph",
            "ivy-next-line", "mouse-drag-region", "mouse-set-point",
            "move-end-of-line"
        ]
    }

    def __init__(self, logfile):
        fp = open(logfile, "r")
        self.nSessions = 0
        self.nCmds = 0
        self.cmds = {}
        self.keys = {}
        self.cmdGroups = {}
        for line in fp.readlines():
            line = line.rstrip()
            ## save-buffers-kill-emacs C-q C-e
            (cmd, key) = string.split(line, " ", 1)
            # HACK in cmdlogger.el to save space!
            if cmd == ".":
                cmd = "self-insert-command"
            if self.cmdType(cmd) == "quit":
                self.nSessions += 1
            if cmd not in self.cmds:
                self.cmds[cmd] = 0
            self.cmds[cmd] += 1
            if key not in self.keys:
                self.keys[key] = 0
            cmdt = self.cmdType(cmd)
            if cmdt not in self.cmdGroups:
                self.cmdGroups[cmdt] = 0
            self.cmdGroups[cmdt] += 1
            self.keys[key] += 1
            self.nCmds += 1
        fp.close()
        self.__convert()

    def __convert(self):
        for c in self.cmds.keys():
            self.cmds[c] = float(self.cmds[c]) / self.nCmds * 100.0
        for k in self.keys.keys():
            self.keys[k] = float(self.keys[k]) / self.nCmds * 100.0
        for t in self.cmdGroups.keys():
            self.cmdGroups[t] = float(self.cmdGroups[t]) / self.nCmds * 100.0

    def cmdType(self, cmd):
        for key in self.CmdTypes.keys():
            arr = self.CmdTypes[key]
            # exact string match?
            if cmd in arr:
                return key
            # re match?
            for a in arr:
                if re.search(a, cmd):
                    return key
        return "others"


class Printer(object):
    def __init__(self, data, **kwargs):
        self.data = data
        self.params = self.getDefaultParams()
        self.params.update(kwargs)

    def getDefaultParams(self):
        return {}

    def show(self):
        raise Exception("'show' should be implemented!")

class Summarizer(Printer):
    def getDefaultParams(self):
        return {'topn': 20}

    def show(self):
        topn = self.params["topn"]
        cmds = self.data.cmds
        keys = self.data.keys
        cs = cmds.keys()
        cs.sort(key=lambda x: cmds[x], reverse=True)
        ks = keys.keys()
        ks.sort(key=lambda x: keys[x], reverse=True)
        if topn < 0:
            topn = max(len(ks), len(cs))
        print("Num Sessions: %d" % self.data.nSessions)
        print("Num Commands: %d" % self.data.nCmds)
        print("%4s  %40s %6s  %20s %6s" % ("Idx", "Command", "%", "Key", "%"))
        for i in range(topn):
            if i < len(cs):
                c = cs[i]
                c_cnt = "%6.2f" % cmds[c]
            else:
                c = c_cnt = ""
            if i < len(ks):
                k = ks[i]
                k_cnt = "%6.2f" % keys[k]
            else:
                k = k_cnt = ""
            print("%4d. %40s %6s  %20s %6s" % (i, c, c_cnt, k, k_cnt))

class Grouper(Printer):
    def show(self):
        grps = self.data.cmdGroups
        grpKeys = grps.keys()
        grpKeys.sort(key=lambda x: grps[x], reverse=True)
        nGroups = len(grpKeys)
        print("Num Groups: %d" % nGroups)
        print("%3s  %10s %6s" % ("Idx", "Group", "%"))
        for i in range(nGroups):
            print("%3d. %10s %6.2f" % (i, grpKeys[i], grps[grpKeys[i]]))


def printerFactory(name, data, **kwargs):
    return eval("%s(data, **kwargs)" % name)

def parseArgs():
    parser = argparse.ArgumentParser(description="CmdLogger Analyzer")
    parser.add_argument("-topn", default=20, type=int,
                        help="Print only 'topn' cmds/keys. <0 means print all")
    parser.add_argument("log", nargs=1, type=str,
                        help="Path to the keys.txt logfile")
    parser.add_argument("printer", default="Summarizer", nargs=1,
                        choices=["Summarizer", "Grouper"],
                        help="Printer class")
    return parser.parse_args()


if __name__ == "__main__":
    args = parseArgs()
    data = Data(args.log[0])
    printerFactory(args.printer[0], data, **vars(args)).show()
