package main_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/multiplay/go-ts3"
	"github.com/pkg/errors"
)

/* Constants and structs */

const checkNickname = "SinusBot via GitHub Actions"

type SinusBotInstance struct {
	UUID string `json:"uuid"`
}

func getDiscordToken() string {
	return os.Getenv("DISCORD_API_KEY")
}

type DiscordInstanceResponse struct {
	Success bool   `json:"success"`
	UUID    string `json:"uuid"`
}

type DefaultBotIdResponse struct {
	DefaultBotID string `json:"defaultBotId"`
}

type LoginResponse struct {
	Token string `json:"token"`
}

type UserNotConnectedError struct {
	Message string `json:"message"`
	Code    int    `json:"code"`
}

/* Automated test functions */

func TestIsBotRunning(t *testing.T) {
	if _, err := getBotID(); err != nil {
		t.Fatalf("could not get botId: %v", err)
	}
}

func TestDiscord(t *testing.T) {
	botId, err := getBotID()
	if err != nil {
		t.Fatalf("could not get botId: %v", err)
	}
	pw, err := ioutil.ReadFile(".password")
	if err != nil {
		t.Fatalf("could not read password file")
	}
	discordApiToken := getDiscordToken()
	if discordApiToken == "" {
		t.Fatalf("could not read discord token env")
	}
	token, err := login("admin", string(pw), *botId)
	if err != nil {
		t.Fatalf("could not get token: %v", err)
	}
	uuid, err := createDiscordInstance(discordApiToken, *token)
	if err != nil {
		t.Fatalf("could not create instance: %v", err)
	}
	fmt.Printf("Created instance %v\n", *uuid)

	if err := updateInstance(*uuid, *token, true, "152947849393471488/454634325556854796"); err != nil {
		t.Fatalf("could not change instance settings: %v", err)
	}

	if err := spawnInstance(*uuid, *token); err != nil {
		t.Fatalf("could not spawn discord instance: %v", err)
	}
	/* Workaround for SinusBot bug */
	if err := updateInstance(*uuid, *token, true, "152947849393471488/452453323891671041"); err != nil {
		t.Fatalf("could not change instance settings: %v", err)
	}

	if err := killInstance(*uuid, *token); err != nil {
		t.Fatalf("could not kill discord instance: %v", err)
	}

	if err := spawnInstance(*uuid, *token); err != nil {
		t.Fatalf("could not spawn discord instance: %v", err)
	}

	time.Sleep(5 * time.Second)
	/* End workaround */

	var to string
	to = "454634325556854796"
	success, err := moveBot(&discordApiToken, &to)
	if err != nil {
		t.Fatalf("Something went wrong at discord: %v", err)
	}

	if success {
		fmt.Printf("Bot is connected\n")
		_, err = moveBot(&discordApiToken, nil)
		if err != nil {
			t.Fatalf("Something went wrong at discord: %v", err)
		}
		if err := killInstance(*uuid, *token); err != nil {
			t.Fatalf("could not kill discord instance: %v", err)
		}
	} else {
		if err := killInstance(*uuid, *token); err != nil {
			t.Fatalf("could not kill discord instance: %v", err)
		}
		fmt.Printf("Bot couldn't be found\n")
	}
}

func TestConnectToTeamSpeak(t *testing.T) {
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
	if err := updateInstance(bots[0].UUID, *token, false, "sinusbot.com"); err != nil {
		t.Fatalf("could not change instance settings: %v", err)
	}
	fmt.Println("Sleeping so that the bot will connect in this time to the server")
	time.Sleep(20 * time.Second)
}

func TestIsBotOnTeamSpeak(t *testing.T) {
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
		if strings.Contains(client.Nickname, checkNickname) {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("no client found")
	}
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
	if err := killInstance(bots[0].UUID, *token); err != nil {
		t.Fatalf("could not kill teamspeak instance: %v", err)
	}
}

/* Logical functions used by tests */

func createDiscordInstance(discordApiToken string, token string) (*string, error) {
	postData, err := json.Marshal(map[string]string{
		"backend": "discord",
		"nick":    checkNickname,
		"token":   discordApiToken,
	})
	resp, err := executePostRequest("/bot/instances", http.StatusCreated, &token, bytes.NewBuffer(postData))
	if err != nil {
		return nil, errors.Wrap(err, "could not create instance")
	}
	var instance DiscordInstanceResponse
	if err := json.NewDecoder(resp.Body).Decode(&instance); err != nil {
		return nil, errors.Wrap(err, "could not decode data")
	}

	return &instance.UUID, nil
}

func getInstances(token string) ([]SinusBotInstance, error) {
	resp, err := executeGetRequest("/bot/instances", &token)
	if err != nil {
		return nil, errors.Wrap(err, "could not get instances")
	}
	var data []SinusBotInstance
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, errors.Wrap(err, "could not decode json")
	}
	return data, nil
}

func updateInstance(uuid string, token string, isDiscord bool, arg string) error {
	var data []byte
	var jsonErr error
	if isDiscord {
		data, jsonErr = json.Marshal(map[string]string{
			"instanceId":  uuid,
			"nick":        checkNickname,
			"channelName": arg,
		})
	} else {
		data, jsonErr = json.Marshal(map[string]string{
			"instanceId": uuid,
			"nick":       checkNickname,
			"serverHost": arg,
		})
	}
	if jsonErr != nil {
		return errors.Wrap(jsonErr, "Could not create json")
	}
	_, err := executePostRequest("/bot/i/"+uuid+"/settings", http.StatusOK, &token, bytes.NewBuffer(data))
	if err != nil {
		return errors.Wrap(err, "could not change instance settings")
	}
	return nil
}

func killInstance(uuid string, token string) error {
	_, err := executePostRequest("/bot/i/"+uuid+"/kill", http.StatusOK, &token, nil)
	if err != nil {
		return errors.Wrap(err, "could not kill instance")
	}
	return nil
}

func spawnInstance(uuid string, token string) error {
	_, err := executePostRequest("/bot/i/"+uuid+"/spawn", http.StatusOK, &token, nil)
	if err != nil {
		return errors.Wrap(err, "could not spawn instance")
	}
	return nil
}

func getBotID() (*string, error) {
	resp, err := executeGetRequest("/botId", nil)
	if err != nil {
		return nil, errors.Wrap(err, "could not get")
	}
	var dbr DefaultBotIdResponse
	if err := json.NewDecoder(resp.Body).Decode(&dbr); err != nil {
		return nil, errors.Wrap(err, "could not decode data")
	}
	return &dbr.DefaultBotID, nil
}

func login(username string, password string, botId string) (*string, error) {
	data, err := json.Marshal(map[string]string{
		"username": username,
		"password": password,
		"botId":    botId,
	})
	if err != nil {
		return nil, errors.Wrap(err, "could not marshal json")
	}

	resp, err := executePostRequest("/bot/login", http.StatusOK, nil, bytes.NewBuffer(data))
	if err != nil {
		return nil, errors.Wrap(err, "could not post")
	}
	var lr LoginResponse
	if err := json.NewDecoder(resp.Body).Decode(&lr); err != nil {
		return nil, errors.Wrap(err, "could not decode json")
	}
	return &lr.Token, nil
}

func moveBot(discordApiToken *string, toChannel *string) (bool, error) {
	data, err := json.Marshal(map[string]*string{
		"channel_id": toChannel,
	})
	if err != nil {
		return false, errors.Wrap(err, "could not marshal json")
	}
	req, err := http.NewRequest("PATCH", "https://discord.com/api/v10/guilds/152947849393471488/members/1027147952696873011", bytes.NewBuffer(data))
	if err != nil {
		return false, errors.Wrap(err, "could not create request")
	}
	req.Header.Add("Authorization", "Bot "+*discordApiToken)
	req.Header.Add("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return false, errors.Wrap(err, "could not do request")
	}
	if resp.StatusCode == http.StatusOK {
		return true, nil
	}
	var errorResponse UserNotConnectedError
	if err := json.NewDecoder(resp.Body).Decode(&errorResponse); err != nil {
		return false, errors.Wrap(err, "could not decode data")
	}
	if errorResponse.Code == 40032 {
		return false, nil // This is a known bug in sinusbot rn
	} else {
		return false, fmt.Errorf("Unknown error occured: %d (%v)", errorResponse.Code, errorResponse.Message)
	}
}

/* SinusBot api wrapper */

func executePostRequest(endpoint string, expectedStatusCode int, token *string, data *bytes.Buffer) (*http.Response, error) {
	var req *http.Request
	var err error
	if data != nil {
		req, err = http.NewRequest("POST", "http://127.0.0.1:8087/api/v1"+endpoint, data)
	} else {
		req, err = http.NewRequest("POST", "http://127.0.0.1:8087/api/v1"+endpoint, nil)
	}
	if err != nil {
		return nil, errors.Wrap(err, "could not create request")
	}
	if token != nil {
		req.Header.Add("Authorization", "Bearer "+*token)
	}
	req.Header.Add("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, errors.Wrap(err, "could not do request")
	}
	if resp.StatusCode != expectedStatusCode {
		return nil, fmt.Errorf("invalid status code received while executing call")
	}
	return resp, nil
}

func executeGetRequest(endpoint string, token *string) (*http.Response, error) {
	req, err := http.NewRequest("GET", "http://127.0.0.1:8087/api/v1"+endpoint, nil)
	if err != nil {
		return nil, errors.Wrap(err, "could not create request")
	}
	if token != nil {
		req.Header.Add("Authorization", "Bearer "+*token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, errors.Wrap(err, "could not do request")
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("invalid status code received while executing call")
	}
	return resp, nil
}
