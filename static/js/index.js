"use strict"

const messagesBoard = document.getElementById("message-board");
const messageForm = document.getElementById("new-message");

async function loadMessages() {
  const request = new Request("/messages");
  const response = await fetch(request);

  response.json().then((messages) => {
    messagesBoard.innerHTML = "";
    messages.forEach(msg => {
      let text = document.createTextNode(msg.author + " wrote: " + msg.content);
      let li = document.createElement("li");
      li.appendChild(text);
      messagesBoard.prepend(li);
    });
  });
}

async function newMessage() {
  let formData = new FormData(messageForm);
  let formJSON = JSON.stringify(Object.fromEntries(formData))
  let request = new Request("/new", { method: "POST", body: formJSON });
  await fetch(request);
  loadMessages();
}

window.onload = function () {
  loadMessages();
}

messageForm.onsubmit = function (event) {
  event.preventDefault();
  newMessage();
}

