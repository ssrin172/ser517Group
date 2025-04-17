# Backend Setup

This project uses **Node.js** and **npm** for managing the backend. Follow the steps below to set up and run the backend locally.

## Prerequisites

Before you start, ensure you have the following installed on your system:

- **Node.js** (v14 or higher)
- **npm** (v6 or higher)

You can download Node.js from [here](https://nodejs.org/).

## Installation

1. **Clone the repository:**

   If you haven't already cloned the repository, run:

   ```bash
   git clone <repository_url>
   cd <project_directory>
   ```
2. **Install Dependencies:**

  Install the necessary dependencies by running:

  ```bash
  npm i
  ```

3. **Running the Development Server:**

  After the dependencies are installed, start the development server with:

  ```bash
  npm run dev
  ```

## Install Dependencies
```
npm install
```

## Environment Setup
```
PORT= {Port no.}
MONGODB_URI= {Link to your mongoDB uri}


# POSTMAN APIs: (GET/POST)
CREATEORUPDATESENSORS= {your api request}
GETSENSORSDATA= {your api request}
```

## Adding Initial Sensors Data to database (Optional)
```
node src/scripts/seedSensors.js
```
Replace seedSensors.js with the actual name of the file where your actual data to be pushed is stored
