(async () => {
  try {

    const delay = ms => new Promise(resolve => setTimeout(resolve, ms))

    console.log('Deploy Start')
  
    const accounts = await web3.eth.getAccounts()
    // marco 0x2511eA7D43F234F7ccc6444c6B0B4f3dbc7513E3
    //Dav 0xc68121B29035A7975b0033a2b5820E86E7b48D9e
    //Matteo 0xb0D0FE284cCDD580881d757972673b90327B37A8
    // 0xf25509d6FDDEC66Da90670BfABAE8Ba8ED3a9511

    const addressToSendToken = "0x2511eA7D43F234F7ccc6444c6B0B4f3dbc7513E3"
    const premiumAddress = "0xc2d8F1FF35f159ef1f857F6E1649e34566F4c2cC"
    const governance = "0x2F084408Ff6235373a708D6BD4ce4e5024F79b82"

    const metadataHexString = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/HexStrings.json'))
    const metadataNFTGeneratorSupport = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/NFTGeneratorSupport.json'))
    const metadataNFTBaseChips = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/NFTBaseChips.json'))

    const metadataUSDT = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/tokens/artifacts/TetherToken.json'))
    const metadataWBTC = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/tokens/artifacts/WBTC.json'))
    const metadataXMT = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/tokens/artifacts/MetalSwap.json'))

    const metadataNFTDescriptor = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/NFTDescriptor.json'))

    
    let libraryHexString = new web3.eth.Contract(metadataHexString.abi)
    libraryHexString = libraryHexString.deploy({
      data: metadataHexString.data.bytecode.object,
      arguments: []
    })
    
    const newlibraryHexString = await libraryHexString.send({
      from: accounts[0],
    })
    console.log('HexString -> ' + newlibraryHexString.options.address )

    
    const metadataURIInfo= JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/URIInfo.json'))

    let contractmetadataURIInfo = new web3.eth.Contract(metadataURIInfo.abi)
    contractmetadataURIInfo = contractmetadataURIInfo.deploy({
      data: metadataURIInfo.data.bytecode.object,
      arguments: []
    })
    const newContractmetadataURIInfo = await contractmetadataURIInfo.send({
      from: accounts[0],
    })
    console.log('URIInfo -> ' + newContractmetadataURIInfo.options.address )

    let libraryNFTGeneratorSupport = new web3.eth.Contract(metadataNFTGeneratorSupport.abi)
    libraryNFTGeneratorSupport = libraryNFTGeneratorSupport.deploy({
      data: metadataNFTGeneratorSupport.data.bytecode.object,
      arguments: []
    })

    const newlibraryNFTGeneratorSupport = await libraryNFTGeneratorSupport.send({
      from: accounts[0],
      gas: 30000000
    })
    console.log('NFTGeneratorSupport -> ' + newlibraryNFTGeneratorSupport.options.address)

 
    let librarymetadataNFTBaseChips = new web3.eth.Contract(metadataNFTBaseChips.abi)
    librarymetadataNFTBaseChips = librarymetadataNFTBaseChips.deploy({
      data: metadataNFTBaseChips.data.bytecode.object,
      arguments: []
    })

    const newlibrarymetadataNFTBaseChips = await librarymetadataNFTBaseChips.send({
      from: accounts[0],
      gas: 30000000
    })
    console.log('NFTBaseChips -> '+ newlibrarymetadataNFTBaseChips.options.address)
  
  const metadataNFTGenerator = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/NFTGenerator.json'))
    let librarymetadataNFTGenerator = new web3.eth.Contract(metadataNFTGenerator.abi)
    librarymetadataNFTGenerator = librarymetadataNFTGenerator.deploy({
      data: metadataNFTGenerator.data.bytecode.object,
      arguments: []
    })

    const newlibrarymetadataNFTGenerator = await librarymetadataNFTGenerator.send({
      from: accounts[0],
      gas: 30000000
  
    })  
    console.log('NFTGenerator -> '+ newlibrarymetadataNFTGenerator.options.address)


    let contractUSDT = new web3.eth.Contract(metadataUSDT.abi)
    let contractWBTC = new web3.eth.Contract(metadataWBTC.abi)
    let contractXMT = new web3.eth.Contract(metadataXMT.abi)

  
    contractUSDT = contractUSDT.deploy({
      data: metadataUSDT.data.bytecode.object,
      arguments: ["10000000000000000000", "Fake USDT","USDT", "6" ]
    })
    
    contractWBTC = contractWBTC.deploy({
      data: metadataWBTC.data.bytecode.object,
      arguments: [ ]
    })
   
    contractXMT = contractXMT.deploy({
      data: metadataXMT.data.bytecode.object,
      arguments: [accounts[0],"1000000000000000000000000000000" ]
    })

    const newContractInstanceUSDT = await contractUSDT.send({
      from: accounts[0],
    })
    console.log('Fake USDT -> ' + newContractInstanceUSDT.options.address)
    const addressUSDT = newContractInstanceUSDT.options.address
  
  
    const newContractInstanceWBTC = await contractWBTC.send({
      from: accounts[0],
    })
    console.log('Fake WBTC -> ' + newContractInstanceWBTC.options.address)
    

  
     const newContractInstanceXMT = await contractXMT.send({
      from: accounts[0],
    })
    console.log('Test XMT -> ' + newContractInstanceXMT.options.address)
   

    await newContractInstanceWBTC.methods.mint(accounts[0], "10000000000000000000").send({ from: accounts[0] })

    await newContractInstanceWBTC.methods.transfer(addressToSendToken,"1000000000").send({ from: accounts[0] })

    await newContractInstanceUSDT.methods.transfer(addressToSendToken,"100000000000").send({ from: accounts[0] })


    let contractNFTDescriptor = new web3.eth.Contract(metadataNFTDescriptor.abi)
    contractNFTDescriptor = contractNFTDescriptor.deploy({
      data: metadataNFTDescriptor.data.bytecode.object,
      arguments: [newlibrarymetadataNFTGenerator.options.address, newContractInstanceWBTC.options.address ,newContractInstanceUSDT.options.address, "20000000000000000000", "100000000", "20000000000"]
    })
   
    const newContractInstanceNFTDescriptor = await contractNFTDescriptor.send({
      from: accounts[0], 
      gas: 30000000
    })
    console.log('NFTDescriptor -> ' + newContractInstanceNFTDescriptor.options.address)


    const metadataPoolETH = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/ETHPool.json'))
    const metadataPoolUSDT = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/USDTPool.json'))
    const metadataPoolWBTC = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/WBTCPool.json'))

    let contracPoolETH = new web3.eth.Contract(metadataPoolETH.abi)
    let contractPoolUSDT = new web3.eth.Contract(metadataPoolUSDT.abi)
    let contractPoolWBTC = new web3.eth.Contract(metadataPoolWBTC.abi)

    
    contracPoolETH = contracPoolETH.deploy({
      data: metadataPoolETH.data.bytecode.object,
      arguments: ["0x0000000000000000000000000000000000000000",newContractInstanceXMT.options.address,newContractInstanceNFTDescriptor.options.address,"100000000000000000"]
    })
    
    contractPoolUSDT = contractPoolUSDT.deploy({
      data: metadataPoolUSDT.data.bytecode.object,
      arguments: [newContractInstanceUSDT.options.address,newContractInstanceXMT.options.address,newContractInstanceNFTDescriptor.options.address,"200000000"]
    })
   
    contractPoolWBTC = contractPoolWBTC.deploy({
      data: metadataPoolWBTC.data.bytecode.object,
      arguments: [newContractInstanceWBTC.options.address,newContractInstanceXMT.options.address,newContractInstanceNFTDescriptor.options.address,"100000" ]
    })
   
    const newContractInstancePoolETH = await contracPoolETH.send({
      from: accounts[0],
      gas: 30000000
    })
     console.log('Pool ETH -> ' + newContractInstancePoolETH.options.address)
   
  
    const newContractInstancePoolUSDT = await contractPoolUSDT.send({
      from: accounts[0],
      gas: 30000000
    })
    console.log('Pool USDT -> ' + newContractInstancePoolUSDT.options.address)
 
   
    const newContractInstancePoolWBTC = await contractPoolWBTC.send({
      from: accounts[0],
      gas: 30000000
    })
    console.log('Pool WBTC -> ' + newContractInstancePoolWBTC.options.address)
      

  await newContractInstancePoolETH.methods.setLockupPeriod("86400").send({ from: accounts[0] })
  await newContractInstancePoolUSDT.methods.setLockupPeriod("86400").send({ from: accounts[0] })
  await newContractInstancePoolWBTC.methods.setLockupPeriod("86400").send({ from: accounts[0] })


  await newContractInstanceXMT.methods.approve(newContractInstancePoolETH.options.address,"1000000000000000000000000").send({ from: accounts[0] })
  await newContractInstanceXMT.methods.approve(newContractInstancePoolUSDT.options.address,"1000000000000000000000000").send({ from: accounts[0] })
  await newContractInstanceXMT.methods.approve(newContractInstancePoolWBTC.options.address,"1000000000000000000000000").send({ from: accounts[0] })

  await newContractInstancePoolETH.methods.finalizePool("100000000000000000000000","10000000000000000000000","Test ETH Staking Pool","placeholder").send({ from: accounts[0] })
  await newContractInstancePoolUSDT.methods.finalizePool("100000000000000000000000","10000000000000000000000","Test USDT Staking Pool","placeholder").send({ from: accounts[0] })
  await newContractInstancePoolWBTC.methods.finalizePool("100000000000000000000000","10000000000000000000000","Test WBTC Staking Pool","placeholder").send({ from: accounts[0] })


  const metadataSettlementFeeContainer = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/SettlementFeeContainer.json'))
  let contracSettlementFeeContainer = new web3.eth.Contract(metadataSettlementFeeContainer.abi)
  
    contracSettlementFeeContainer = contracSettlementFeeContainer.deploy({
      data: metadataSettlementFeeContainer.data.bytecode.object,
      arguments:["Test SettlementFeeContainer"] 
    })

  const newContractInstanceSettlementFeeContainer = await contracSettlementFeeContainer.send({
      from: accounts[0]
    })
  console.log('SettlementFeeContainer -> ' + newContractInstanceSettlementFeeContainer.options.address )
  

  const metadataFeeManagerETHUSDTSwap  = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/FeeManager.json'))
  let contracFeeManagerETHUSDTSwap = new web3.eth.Contract(metadataFeeManagerETHUSDTSwap.abi)

     contracFeeManagerETHUSDTSwap = contracFeeManagerETHUSDTSwap.deploy({
      data: metadataFeeManagerETHUSDTSwap.data.bytecode.object,
      arguments:["10000","1500000",accounts[0],"Test FeeManager ETHUSDTSwap"] 
    })
  
   const newContractInstanceFeeManagerETHUSDTSwap = await contracFeeManagerETHUSDTSwap.send({
      from: accounts[0],
      gas: 30000000
    })
  console.log('FeeManagerETHUSDTSwap -> ' + newContractInstanceFeeManagerETHUSDTSwap.options.address)
  


  const metadataFeeManagerWBTCUSDTSwap  = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/libraries/artifacts/FeeManager.json'))
  let contracFeeManagerWBTCUSDTSwap = new web3.eth.Contract(metadataFeeManagerWBTCUSDTSwap.abi)  

  contracFeeManagerWBTCUSDTSwap = contracFeeManagerWBTCUSDTSwap.deploy({
      data: metadataFeeManagerWBTCUSDTSwap.data.bytecode.object,
      arguments:["15000","1500000", accounts[0], "Test FeeManager WBTCUSDTSwap"] 
    })
 
   const newContractInstanceFeeManagerWBTCUSDTSwap= await contracFeeManagerWBTCUSDTSwap.send({
      from: accounts[0],
      gas: 30000000
    })
  console.log('FeeManagerWBTCUSDTSwap -> ' + newContractInstanceFeeManagerWBTCUSDTSwap.options.address)
  
  const metadataETHUSDTSwap = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/ETHUSDTSwap.json'))
  let contracETHUSDTSwap = new web3.eth.Contract(metadataETHUSDTSwap.abi)  

  contracETHUSDTSwap = contracETHUSDTSwap.deploy({
      data: metadataETHUSDTSwap.data.bytecode.object,
      arguments:["0x0000000000000000000000000000000000000000",
                newContractInstancePoolETH.options.address,
                "18",
                newContractInstanceUSDT.options.address ,
                newContractInstancePoolUSDT.options.address,
                "6",
                "0x9326BFA02ADD2366b30bacB125260Af641031331",
                newContractInstanceXMT.options.address,
                governance,
                newContractInstanceFeeManagerETHUSDTSwap.options.address
                ] 
    })
  
  const newContractInstanceETHUSDTSwap= await contracETHUSDTSwap.send({
      from: accounts[0],
      gas: 30000000
    })
  console.log('ETHUSDTSwap -> '+ newContractInstanceETHUSDTSwap.options.address )

  await newContractInstanceETHUSDTSwap.methods.finalizeContract("2",
                                                          "2",
                                                          newContractInstanceSettlementFeeContainer.options.address,
                                                          premiumAddress,
                                                          accounts[0],
                                                          "1000000",
                                                          "3600",
                                                          "Test ETHUSDTSwap",
                                                          "placeholder").send({ from: accounts[0] })

  

 const metadataWBTCUSDTSwap = JSON.parse(await remix.call('fileManager', 'getFile', 'browser/contracts/artifacts/WBTCUSDTSwap.json'))
  let contracWBTCUSDTSwap = new web3.eth.Contract(metadataWBTCUSDTSwap.abi)  

  contracWBTCUSDTSwap= contracWBTCUSDTSwap.deploy({
      data: metadataWBTCUSDTSwap.data.bytecode.object,
      arguments:[newContractInstanceWBTC.options.address ,
                newContractInstancePoolWBTC.options.address,
                "8",
                newContractInstanceUSDT.options.address ,
                newContractInstancePoolUSDT.options.address,
                "6",
                "0x6135b13325bfC4B00278B4abC5e20bbce2D6580e",
                newContractInstanceXMT.options.address,
                governance,
                newContractInstanceFeeManagerWBTCUSDTSwap.options.address
                ] 
    })


  const newContractInstanceWBTCUSDTSwap= await contracWBTCUSDTSwap.send({
      from: accounts[0],
      gas: 30000000
    })
  console.log('WBTCUSDTSwap -> ' + newContractInstanceWBTCUSDTSwap.options.address )
 
  await newContractInstanceWBTCUSDTSwap.methods.finalizeContract("2",
                                                          "2",
                                                          newContractInstanceSettlementFeeContainer.options.address,
                                                          premiumAddress,
                                                          accounts[0],
                                                          "1000000",
                                                          "3600",
                                                          "Test WBTCSDTSwap",
                                                          "placeholder").send({ from: accounts[0] })


  await newContractInstancePoolETH.methods.addSwapPairsManagement(newContractInstanceETHUSDTSwap.options.address).send({ from: accounts[0] })
  
  await newContractInstancePoolUSDT.methods.addSwapPairsManagement(newContractInstanceETHUSDTSwap.options.address).send({ from: accounts[0] })
  await newContractInstancePoolUSDT.methods.addSwapPairsManagement(newContractInstanceWBTCUSDTSwap.options.address).send({ from: accounts[0] })

  await newContractInstancePoolWBTC.methods.addSwapPairsManagement(newContractInstanceWBTCUSDTSwap.options.address).send({ from: accounts[0] })


  await newContractInstanceSettlementFeeContainer.methods.addSwapPairsManagement(newContractInstanceETHUSDTSwap.options.address).send({ from: accounts[0] })

  // error 
  await newContractInstanceSettlementFeeContainer.methods.addSwapPairsManagement(newContractInstanceWBTCUSDTSwap.options.address).send({ from: accounts[0] })

  await newContractInstanceXMT.methods.approve(newContractInstanceETHUSDTSwap.options.address, "10000000000000000000000000000000000000000000000").send({ from: accounts[0] })
  await newContractInstanceXMT.methods.approve(newContractInstanceWBTCUSDTSwap.options.address,"10000000000000000000000000000000000000000000000").send({ from: accounts[0] })

  console.log('End Deploy')

  } catch (e) {
    console.log(e.message)
  }
})()



