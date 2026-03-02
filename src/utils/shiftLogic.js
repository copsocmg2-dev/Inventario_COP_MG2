export const getInfoOperacional = (dataRef = new Date()) => {
  const h = dataRef.getHours();
  let turno = '';
  let dataOp = new Date(dataRef);

  if (h >= 6 && h < 14) {
    turno = 'T1';
  } else if (h >= 14 && h < 22) {
    turno = 'T2';
  } else {
    turno = 'T3';
    // Se for entre 00h e 05:59h, considera dia anterior
    if (h < 6) {
      dataOp.setDate(dataOp.getDate() - 1);
    }
  }

  const year = dataOp.getFullYear();
  const month = String(dataOp.getMonth() + 1).padStart(2, '0');
  const day = String(dataOp.getDate()).padStart(2, '0');
  const dataStr = `${year}-${month}-${day}`;

  return { turno, dataOperacional: dataStr, timestamp: dataOp };
};