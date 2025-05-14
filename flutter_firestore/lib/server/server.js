const express = require('express');
const axios = require('axios');
const cors = require('cors');
const Papa = require('papaparse');

const app = express();
const PORT = 3001;

const influxURL = 'http://localhost:8086/api/v2/query';
const influxToken = 'L9DloOT0zJYUCYavaCbZEfL1ms6YvKlH1_zEROYhjYDxhgKOx-Bazl9I9xJJq_x20JyMjXcY0hvyz2qWfcwzqA==';
const bucketName = 'met';
const orgName = 'Rmutto'; // เปลี่ยนตรงนี้ให้ตรงกับของคุณ

app.use(cors());

// กำหนด URL ที่จะดึงข้อมูลจาก InfluxDB
app.get('/get-influx-data', async (req, res) => {
  try {
    const fluxQuery = `
      water = from(bucket: "${bucketName}")
        |> range(start: -1h)
        |> filter(fn: (r) => r._measurement == "water_meter_data" and r._field == "value")

      energy = from(bucket: "${bucketName}")
        |> range(start: -1h)
        |> filter(fn: (r) => r._measurement == "energy_meter/data" and r._field == "value")

      union(tables: [water, energy])
    `;

    const response = await axios.post(
      `${influxURL}?org=${orgName}`,
      fluxQuery,
      {
        headers: {
          'Authorization': `Token ${influxToken}`,
          'Content-Type': 'application/vnd.flux',
          'Accept': 'text/csv'
        },
        responseType: 'text'
      }
    );

    // ใช้ PapaParse แปลง CSV -> JSON
    const parsed = Papa.parse(response.data, {
      header: true,
      skipEmptyLines: true
    });

    // แปลงข้อมูลให้เรียบง่าย โดยไม่ทำการคำนวณ
    const cleanData = parsed.data.map((row) => {
      const value = parseFloat(row._value);
      const type = row._measurement.includes('energy') ? 'energy' : 'water';
      const time = row._time;

      // ส่งข้อมูลค่าน้ำและค่าไฟแบบดิบ (raw values) โดยไม่มีการคำนวณ
      return {
        type,
        time,
        value: isNaN(value) ? 0.0 : value, // ถ้าแปลงไม่ได้จะใช้ค่า 0.0
      };
    });

    // ส่งข้อมูลดิบจาก InfluxDB (ค่าที่ไม่ได้คำนวณ)
    res.json(cleanData);

  } catch (error) {
    console.error('❌ ERROR:', error.response?.data || error.message);
    res.status(500).send('Error fetching InfluxDB data');
  }
});

app.listen(PORT, () => {
  console.log(`✅ Server running at http://localhost:${PORT}`);
});
