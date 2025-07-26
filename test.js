const request = require('supertest');
const { app, server } = require('./app');
const { expect } = require('chai');

describe('API Tests', () => {
    after(() => {
        server.close();
    });

    describe('GET /', () => {
        it('should return Hello World!', async () => {
            const res = await request(app).get('/');
            expect(res.status).to.equal(200);
            expect(res.text).to.equal('Hello World!');
        });
    });

    describe('GET /health', () => {
        it('should return healthy status', async () => {
            const res = await request(app).get('/health');
            expect(res.status).to.equal(200);
            expect(res.body).to.deep.equal({ status: 'healthy' });
        });
    });

    describe('GET /metrics', () => {
        it('should return prometheus metrics', async () => {
            const res = await request(app).get('/metrics');
            expect(res.status).to.equal(200);
            expect(res.type).to.contain('text/plain');
            expect(res.text).to.include('http_requests_total');
        });
    });
});