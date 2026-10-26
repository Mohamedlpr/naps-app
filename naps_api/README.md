# NAPS API

The API provides shared sign-in, task, support request, announcement, and team data for the Flutter app. MongoDB is the source of truth, so staff see the same organization data after signing in from different devices.

## Run locally with Docker

1. Install Docker Desktop.
2. Copy `.env.example` to `.env` and replace both sample secrets with long, random values.
3. Run `docker compose up --build` from this folder.
4. Confirm the API is running at `http://localhost:4000/health`.
5. In the Flutter app, set the API address to `http://10.0.2.2:4000/api` for an Android emulator, or to the computer's LAN address for a physical phone.
6. From the app's first-use setup, enter the `BOOTSTRAP_SECRET` to create the organization and its first administrator. This setup closes once an account has been created.

The Compose database is intended for local development. For staff access over the internet, deploy the API behind HTTPS and use a managed MongoDB service.

## Run locally without Docker

1. Install Node.js 20.19 or newer and MongoDB.
2. Copy `.env.example` to `.env` and set separate random values for `JWT_SECRET` and `BOOTSTRAP_SECRET`.
3. Install the packages with `npm install`.
4. Start MongoDB, then run `npm run dev`.
5. In the Flutter app, set the API address to `http://10.0.2.2:4000/api` for an Android emulator, or to the computer's LAN address for a physical phone.
6. From the app's first-use setup, enter the `BOOTSTRAP_SECRET` to create the organization and its first administrator. This setup closes once an account has been created.

The first administrator can add supervisors and staff accounts from the team page. Passwords are stored as salted scrypt hashes. Sessions use signed eight-hour tokens. Every data query is scoped to the signed-in organization, and employee task access is limited to tasks assigned to that employee.

## Production deployment

Deploy the API behind HTTPS and connect it to a managed MongoDB deployment. Set all five environment variables from the deployment provider's secret manager. Set `CORS_ORIGIN` to the exact web origins that may call the API; mobile clients do not use browser CORS checks. Do not reuse the bootstrap secret as the JWT secret, and rotate the bootstrap secret after organization setup.

This repository contains the application code, not a hosted API or a MongoDB account. The shared app becomes live when the API and database are deployed and the Flutter client is configured with that API address.

## Free pilot deployment with Render and MongoDB Atlas

This repository includes a Render Blueprint at the repository root. Create an Atlas Free cluster, add a database user, and allow network access from `0.0.0.0/0` so Render can connect. Use a strong unique password in the MongoDB connection string; enter that URI only in Render's secret prompt.

Push this repository to a private GitHub repository, then in Render choose **New > Blueprint** and connect that repository. Render reads `render.yaml` and prompts for `MONGODB_URI` and `BOOTSTRAP_SECRET`; enter both in the Render dashboard, not in source control. Render generates the JWT secret. Once deployment is healthy, copy the HTTPS service URL and set the app's API address to `<service-url>/api` from the connection setup on the sign-in screen.

Use the bootstrap secret once to create the organization administrator, then rotate or remove it in Render. Free Render services sleep after inactivity, so the first request may take about a minute. Atlas Free storage is limited; this setup is for a pilot and does not include a production backup plan.
