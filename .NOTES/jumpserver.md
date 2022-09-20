





# api auth

https://docs.jumpserver.org/zh/master/dev/rest_api/#api_1



https://docs.jumpserver.org/zh/master/dev/rest_api/



```go
// Golang 示例
package main

import (
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "time"
    "gopkg.in/twindagger/httpsig.v1"
)

const (
    JmsServerURL = "https://demo.jumpserver.org"
    AccessKeyID = "f7373851-ea61-47bb-8357-xxxxxxxxxxx"
    AccessKeySecret = "d6ed1a06-66f7-4584-af18-xxxxxxxxxxxx"
)

type SigAuth struct {
    KeyID    string
    SecretID string
}

func (auth *SigAuth) Sign(r *http.Request) error {
    headers := []string{"(request-target)", "date"}
    signer, err := httpsig.NewRequestSigner(auth.KeyID, auth.SecretID, "hmac-sha256")
    if err != nil {
        return err
    }
    return signer.SignRequest(r, headers, nil)
}

func GetUserInfo(jmsurl string, auth *SigAuth) {
    url := jmsurl + "/api/v1/users/users/"
    gmtFmt := "Mon, 02 Jan 2006 15:04:05 GMT"
    client := &http.Client{}
    req, err := http.NewRequest("GET", url, nil)
    req.Header.Add("Date", time.Now().Format(gmtFmt))
    req.Header.Add("Accept", "application/json")
    req.Header.Add("X-JMS-ORG", "00000000-0000-0000-0000-000000000002")
    if err != nil {
        log.Fatal(err)
    }
    if err := auth.Sign(req); err != nil {
        log.Fatal(err)
    }
    resp, err := client.Do(req)
    if err != nil {
        log.Fatal(err)
    }
    defer resp.Body.Close()
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        log.Fatal(err)
    }
    json.MarshalIndent(body, "", "    ")
    fmt.Println(string(body))
}

func main() {
    auth := SigAuth{
        KeyID:    AccessKeyID,
        SecretID: AccessKeySecret,
    }
    GetUserInfo(JmsServerURL, &auth)
}

```

