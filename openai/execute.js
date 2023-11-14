import OpenAI from "openai";
import dotenv from "dotenv";
//import prompt from './prompt.json' assert { type: 'json' };
import fs from 'fs/promises';

dotenv.config();
const openai = new OpenAI();

// This is intended to be ran once per new dataset intake
// Responses are added to the next query
async function FetchGPTResponse() {
    const prompt = await fs.readFile('openai/prompt.txt', 'utf8');
    const newdata = await fs.readFile('openai/data.txt', 'utf8');

  const completion = await openai.chat.completions.create({
    messages: [ 
        {role: "system", content: prompt},
        {role: "user", content: newdata}
    ],
    model: "gpt-3.5-turbo",
    temperature: 0,
  });

  console.log(completion.choices[0]);
}

FetchGPTResponse();