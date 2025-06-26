const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const OPENAI_API_KEY = [xxxxxx].join("");

const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MODEL_NAME = "gpt-3.5-turbo";

const thresholdMap = {
  Temperature: 33,
  Humidity: 85,
  Pitch: 5,
  Roll: 5,
  Decibel: 85,
  PM1: 35,
  PM2_5: 50,
  PM10: 100,
  no_helmet: 0,
};

const promptMap = {
  Temperature: (v) =>
    `Temperature is ${v}°C. Any advice for construction site workers? (Limit to 30 words.)`,

  Humidity: (v) =>
    `Humidity is ${v}%. Any advice for construction site workers? (Limit to 30 words.)`,

  Pitch: (v) =>
    `Pitch angle is ${v}°. This dangerous for workers ` +
    `Provide construction site safety advice. (Limit to 30 words.)`,

  Roll: (v) =>
    `Roll angle is ${v}°. Explain what risks this may pose ` +
    `and how workers should respond. (Limit to 30 words.)`,

  Decibel: (v) =>
    `Sound level is ${v} dB. This too loud for workers ` +
    `Suggest protective actions for construction sites. (Limit to 30 words.)`,

  PM1: (v) =>
    `PM1.0 concentration is ${v} µg/m³. Explain health risks ` +
    `and protection tips on construction sites. (Limit to 30 words.)`,

  PM2_5: (v) =>
    `PM2.5 concentration is ${v} µg/m³. Explain health risks ` +
    `and protection tips on construction sites. (Limit to 30 words.)`,

  PM10: (v) =>
    `PM10 concentration is ${v} µg/m³. Explain health risks ` +
    `and protection tips on construction sites. (Limit to 30 words.)`,

  no_helmet: (v) =>
    `${v} worker(s) detected without helmet. Provide construction ` +
    `site safety advice. (Limit to 30 words.)`,
};

exports.notifyOnThreshold = functions.database
    .ref("/x/{parameter}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.val();
      const parameter = context.params.parameter;

      console.log("Triggered for:", parameter, "Value:", newValue);

      const threshold = thresholdMap[parameter];

      const isExceeded =
      parameter === "Pitch" || parameter === "Roll" ?
        Math.abs(newValue) > threshold :
        newValue > threshold;

      if (threshold !== undefined && !isExceeded) {
        console.log(`${parameter} (${newValue}) did not exceed threshold (${threshold})`);
        return null;
      }

      const generatePrompt = promptMap[parameter];
      if (!generatePrompt) {
        console.log("No prompt for this parameter.");
        return null;
      }

      const prompt = generatePrompt(newValue);
      let advice = "Please stay safe.";

      try {
        const response = await axios.post(
            OPENAI_URL,
            {
              model: MODEL_NAME,
              messages: [{role: "user", content: prompt}],
              max_tokens: 100,
              temperature: 0.7,
            },
            {
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer " + OPENAI_API_KEY,
              },
            },
        );

        if (
          response &&
        response.data &&
        response.data.choices &&
        response.data.choices[0] &&
        response.data.choices[0].message &&
        response.data.choices[0].message.content
        ) {
          advice = response.data.choices[0].message.content;
        }

        console.log("OpenAI Advice：", advice);
      } catch (error) {
        console.error("OpenAI API Error：", error.message);
      }

      const path = `/x/Recommendation/${parameter}`;
      await admin.database().ref(path).set(advice);

      const payload = {
        notification: {
          title: "Enviornmental Alarm",
          body: `[${parameter}] ${advice}`,
        },
        topic: "alerts",
      };

      try {
        const res = await admin.messaging().send(payload);
        console.log("Successful：", res);
      } catch (err) {
        console.error("Error：", err.message);
      }

      return null;
    });
