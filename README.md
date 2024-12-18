# Fidget Fighter Frontend

Author: Avinh Huynh

This is a mobile game where you and another person have fidget spinners and whoever spins theirs faster wins.

There is a [Fidget Fighter Backend](https://github.com/SlimeyTurtles/fidget-fighter-backend) as well.

To demo this code, you have 2 options:

A) Download the frontend on two phones, and click Find Match. They will find a match against eachother and fight.

B) Connect to the backend using an external tool like PostMan and manually send the api data. It should look something like the following.

![image](https://github.com/user-attachments/assets/0f05a32e-d01d-4cbe-800d-729ba96da1a9)

# To run

### If you are not running the backend yourself:

Download it into xcode and then run it from the simulator or your phone

### If you are running the backend yourself:

In Global.swift > AppConstants > webSocketURL, change this to be your IP Address if you are running the backend

```
struct AppConstants {
  static let webSocketURL = "ws://<YOUR SERVER IP ADDRESS>:3000
}
```

# Milestone 1

-[x] Create a GitHub project, make sure each member is invited as collaborators.
-[x] Submit GitHub link to iLearn
-[x] Create a readme for your team. Your proposal will live in the readme of your project.
-[x] Each member of your team should add their name to the readme and push those changes to
master so we can figure out any GitHub related issues early
-[x] Create a proposal
-[x] Must have features
-[x] Nice to have feature
-[x] Create some basic wire-frames for your main feature

Must have features:

- This project is going to have 2 fidget spinners on 2 different phones and whoever spins the fastest on average will win. 
- A server that hosts the backend for players to connect to
- A home screen with a find match button
- Matchmaking and loading into the game with websockets
- Spinning sending api data to the server and determining a winner

Nice to have features:

- Trophies and a leaderboard
- A shop to buy more fidget spinners

I don't have to worry about distribution of work with teammates because it is only me.

# Milestone 2

![image](https://github.com/user-attachments/assets/9ea3059b-8aae-485c-8854-57f4e4ba8d7b)

![image](https://github.com/user-attachments/assets/c4982f04-19ef-44b5-8f7d-0e7673f6398b)

![image](https://github.com/user-attachments/assets/c5900a98-f134-4734-9590-bab47b51ef1c)

# Milestone 3

Submitting now!
