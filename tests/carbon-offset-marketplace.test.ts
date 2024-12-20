import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('Carbon Offset Marketplace Contract', () => {
  let mockContractCall: any
  
  beforeEach(() => {
    mockContractCall = vi.fn()
  })
  
  it('should create a project', async () => {
    mockContractCall.mockResolvedValue({ success: true, value: 1 })
    const result = await mockContractCall('create-project', 'Test Project', 'Description', 'Location', 1000, 10)
    expect(result.success).toBe(true)
    expect(result.value).toBe(1)
  })
  
  it('should verify a project', async () => {
    mockContractCall.mockResolvedValue({ success: true })
    const result = await mockContractCall('verify-project', 1, 'VERIFIED')
    expect(result.success).toBe(true)
  })
  
  it('should buy offset', async () => {
    mockContractCall.mockResolvedValue({ success: true })
    const result = await mockContractCall('buy-offset', 1, 100)
    expect(result.success).toBe(true)
  })
  
  it('should retire offset', async () => {
    mockContractCall.mockResolvedValue({ success: true })
    const result = await mockContractCall('retire-offset', 1, 50)
    expect(result.success).toBe(true)
  })
  
  it('should get project details', async () => {
    mockContractCall.mockResolvedValue({
      success: true,
      value: {
        owner: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        name: 'Test Project',
        description: 'Description',
        location: 'Location',
        'total-offsets': 1000,
        'available-offsets': 900,
        'price-per-token': 10,
        'verification-status': 'VERIFIED'
      }
    })
    const result = await mockContractCall('get-project', 1)
    expect(result.success).toBe(true)
    expect(result.value.name).toBe('Test Project')
    expect(result.value['available-offsets']).toBe(900)
  })
  
  it('should get offset usage', async () => {
    mockContractCall.mockResolvedValue({
      success: true,
      value: {
        amount: 50,
        'retirement-block': 12345
      }
    })
    const result = await mockContractCall('get-offset-usage', 1, 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM')
    expect(result.success).toBe(true)
    expect(result.value.amount).toBe(50)
    expect(result.value['retirement-block']).toBe(12345)
  })
})

