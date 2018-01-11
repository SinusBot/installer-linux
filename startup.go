package main

import (
	"bufio"
	"fmt"
	"github.com/pkg/errors"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

type parameter struct {
	Value  string
	Detect string
}

type app struct {
	FileName   string
	Parameters []parameter
	command    exec.Cmd
	cmdStdout  io.Reader
	cmdStdin   io.Writer
}

func main() {
	config := app{
		FileName: "./sinusbot_installer.sh",
		Parameters: []parameter{
			parameter{
				Value:  "1",
				Detect: "What should the Installer do?",
			},
			parameter{
				Value:  "1",
				Detect: "Automatic usage or own directories?",
			},
			parameter{
				Value:  "2",
				Detect: "This SinusBot version is only for private use! Accept?",
			},
			parameter{
				Value:  "1",
				Detect: "Should YT-DL be installed/updated?",
			},
			parameter{
				Value:  "1",
				Detect: "Check your time below:",
			},
			parameter{
				Value:  "1",
				Detect: "Update the system packages to the latest version?",
			},
			parameter{
				Detect: "Please enter the name of the sinusbot user.",
			},
			parameter{
				Value: `
				q
				y`,
				Detect: "Welcome to the TeamSpeak 3 Client",
			},
		},
	}
	if err := config.Run(); err != nil {
		log.Fatalf("could not run app: %v", err)
	}

}

func (a *app) checkParameters(history []string, line string) error {
	for key := range a.Parameters {
		if strings.Contains(line, a.Parameters[key].Detect) {
			go func(value string) {
				time.Sleep(1 * time.Second)
				a.writeStdIn(value)
			}(a.Parameters[key].Value)
			break
		}
	}
	return nil
}

func (a *app) Run() error {
	cmd := exec.Command("bash", a.FileName)

	var err error
	a.cmdStdout, err = cmd.StdoutPipe()
	if err != nil {
		return errors.Wrap(err, "could not create stdout pipe")
	}
	cmd.Stderr = cmd.Stdout

	a.cmdStdin, err = cmd.StdinPipe()
	if err != nil {
		return errors.Wrap(err, "could not create stdin pipe")
	}

	go a.cmdListeners()
	if err = cmd.Start(); err != nil {
		return errors.Wrap(err, "could not start process")
	}
	if err = cmd.Wait(); err != nil {
		return errors.Wrap(err, "could not wait for process")
	}
	return nil
}

func (a *app) cmdListeners() {
	scanner := bufio.NewScanner(a.cmdStdout)
	history := []string{}
	for scanner.Scan() {
		line := scanner.Text()
		fmt.Println(line)
		if err := a.checkParameters(history, line); err != nil {
			log.Fatalf("could not check parameters: %v", err)
		}
		history = append(history, line)
	}
}

func (a *app) writeStdIn(action string) {
	action += "\n"
	io.WriteString(a.cmdStdin, action)
	fmt.Fprint(os.Stdout, action)
}
