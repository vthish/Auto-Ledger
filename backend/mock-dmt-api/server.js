const express = require("express");
const cors = require("cors");

const app = express();
const PORT = 4000;

// Enable CORS to allow requests from our NestJS backend (localhost:3000 -> localhost:4000)
app.use(cors());
app.use(express.json());

// Mock Database containing realistic Sri Lankan License Data
const mockDmtDatabase = {
  200204802139: {
    licenseNumber: "B5744142",
    fullName: "KAPPITIYAGODA VITHANAGE VENUSHA THISHAN",
    address: "269 SOUTHERNCOURT MANAVILA WALAHANDUWA GALLE",
    dob: "2002-02-17",
    bloodGroup: "O+",
    dateOfIssue: "2024-05-02",
    vehicleCategories: [
      { class: "A1", issueDate: "2022-07-05", expiryDate: "2030-07-05" },
      { class: "A", issueDate: "2022-07-05", expiryDate: "2030-07-05" },
      { class: "B1", issueDate: "2022-07-05", expiryDate: "2030-07-05" },
      { class: "B", issueDate: "2022-07-05", expiryDate: "2030-07-05" },
      { class: "G1", issueDate: "2022-07-05", expiryDate: "2030-07-05" },
    ],
  },
  // Adding a second dummy user for testing 'Not Found' or other scenarios later
  199812345678: {
    licenseNumber: "B1234567",
    fullName: "SAMPLE DRIVER NAME",
    address: "123 COLOMBO ROAD, GALLE",
    dob: "1998-05-20",
    bloodGroup: "A+",
    dateOfIssue: "2020-01-15",
    vehicleCategories: [
      { class: "B", issueDate: "2020-01-15", expiryDate: "2028-01-15" },
    ],
  },
};

// GET Endpoint to fetch license details by NIC
app.get("/api/dmt/license/:nic", (req, res) => {
  const userNic = req.params.nic;
  const licenseDetails = mockDmtDatabase[userNic];

  if (licenseDetails) {
    // Return 200 OK with data if NIC is found
    res.status(200).json({
      success: true,
      data: licenseDetails,
    });
  } else {
    // Return 404 Not Found if NIC is not in the mock database
    res.status(404).json({
      success: false,
      message: "No driving license found for the provided NIC number",
    });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`[DMT Mock API] Server is running on http://localhost:${PORT}`);
});
