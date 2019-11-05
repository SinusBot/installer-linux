package main_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/multiplay/go-ts3"
	"github.com/pkg/errors"
	"io/ioutil"
	"net/http"
	"strings"
	"testing"
	"time"
)

const teamspeakCheckNickname = "SinusBot via GitHub Actions"

type instance struct {
	UUID string `json:"uuid"`
}

func TestIsBotRunning(t *testing.T) {
	if _, err := getBotID(); err != nil {
		t.Fatalf("could not get botId: %v", err)
	}
}

func TestConnectToTeamspeak(t *testing.T) {
	botId, err := getBotID()
	if err != nil {
		t.Fatalf("could not get botId: %v", err)
	}
	pw, err := ioutil.ReadFile(".password")
	if err != nil {
		t.Fatalf("could not read password file")
	}
	token, err := login("admin", string(pw), *botId)
	if err != nil {
		t.Fatalf("could not get token: %v", err)
	}
	bots, err := getInstances(*token)
	if err != nil {
		t.Fatalf("could not get instances: %v", err)
	}
	if err := changeSettings(bots[0].UUID, *token); err != nil {
		t.Fatalf("could not change instance settings: %v", err)
	}
	fmt.Println("Sleeping so that the bot will connect in this time to the server")
	time.Sleep(5 * time.Second)
}

func TestIsBotOnTeamspeak(t *testing.T) {
	c, err := ts3.NewClient("julia.ts3index.com:10011")
	if err != nil {
		t.Fatalf("could not create new ts3 client: %v", err)
	}
	defer c.Close()
	if err := c.UsePort(1489); err != nil {
		t.Fatalf("could not use port: %v", err)
	}
	clientList, err := c.Server.ClientList()
	if err != nil {
		t.Fatalf("could not get clientlist: %v", err)
	}
	found := false
	for _, client := range clientList {
		if strings.Contains(client.Nickname, teamspeakCheckNickname) {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("no client found")
	}
}

func getInstances(token string) ([]instance, error) {
	req, err := http.NewRequest("GET", "http://127.0.0.1:8087/api/v1/bot/instances", nil)
	if err != nil {
		return nil, errors.Wrap(err, "could not create request")
	}
	req.Header.Add("Authorization", "Bearer "+token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, errors.Wrap(err, "could not do request")
	}
	var data []instance
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, errors.Wrap(err, "could not decode json")
	}
	return data, nil
}

func changeSettings(uuid, token string) error {
	data, err := json.Marshal(map[string]string{
		"instanceId": uuid,
		"nick":       teamspeakCheckNickname,
		"serverHost": "sinusbot.com",
	})
	req, err := http.NewRequest("POST", "http://127.0.0.1:8087/api/v1/bot/i/"+uuid+"/settings", bytes.NewBuffer(data))
	if err != nil {
		return errors.Wrap(err, "could not create request")
	}
	req.Header.Add("Authorization", "Bearer "+token)
	req.Header.Add("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return errors.Wrap(err, "could not do request")
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("invalid status code received by setting instance settings: %d", resp.StatusCode)
	}
	req, err = http.NewRequest("POST", "http://127.0.0.1:8087/api/v1/bot/i/"+uuid+"/spawn", nil)
	if err != nil {
		return errors.Wrap(err, "could not create request")
	}
	req.Header.Add("Authorization", "Bearer "+token)
	resp, err = http.DefaultClient.Do(req)
	if err != nil {
		return errors.Wrap(err, "could not do request")
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("invalid status code received by spawning instance settings")
	}
	return nil
}

func getBotID() (*string, error) {
	resp, err := http.Get("http://127.0.0.1:8087/api/v1/botId")
	if err != nil {
		return nil, errors.Wrap(err, "could not get")
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("status is not expected: %d; got: %d", http.StatusOK, resp.StatusCode)
	}
	var data struct {
		DefaultBotID string `json:"defaultBotId"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, errors.Wrap(err, "could not decode data")
	}
	return &data.DefaultBotID, nil
}

func login(username, password, botId string) (*string, error) {
	data, err := json.Marshal(map[string]string{
		"username": username,
		"password": password,
		"botId":    botId,
	})
	if err != nil {
		return nil, errors.Wrap(err, "could not marshal json")
	}
	resp, err := http.Post("http://127.0.0.1:8087/api/v1/bot/login", "application/json", bytes.NewBuffer(data))
	if err != nil {
		return nil, errors.Wrap(err, "could not post")
	}
	var res struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return nil, errors.Wrap(err, "could not decode json")
	}
	return &res.Token, nil
}
